# link_pulse

*[English version](README.md)*

Um encurtador de URLs feito com Rails 8, Hotwire e ViewComponent.

Colas um link longo, recebes um curto. Cada visita a um link curto é registada
como um evento de clique, e o dashboard mostra os totais por link.

### Como funciona

| Peça | Onde |
|---|---|
| Modelos Link + ClickEvent | `app/models/` |
| Dashboard (estatísticas + tabela) | `app/controllers/dashboard_controller.rb` |
| Redirect do link curto | `app/controllers/redirects_controller.rb` — `GET /l/:short_code` |
| Componentes de UI | `app/components/` (ViewComponent, vendored do Rails Blocks) |
| Controllers Stimulus | `app/javascript/controllers/` |

Criar um link faz POST para `dashboard#generate_short_url`, que responde com um
Turbo Stream a substituir os cards de estatísticas, a tabela e a caixa de
resultado num só pedido. Um pedido HTML normal cai no redirect. Isto é
deliberado — ver a nota sobre atualizações em tempo real nos Próximos Passos.

### Modelo de dados

| Coluna | Notas |
|---|---|
| `links.url` | Obrigatório, índice único. Validado pelo `UrlValidator` |
| `links.short_code` | Índice único. Nullable **por desenho** — ver abaixo |
| `links.click_events_count` | Counter cache mantido pelo `ClickEvent` |
| `click_events` | `link_id` + timestamps, com índice em `[link_id, created_at]` |

O `short_code` é o id do registo codificado em base62, atribuído por um callback
`after_create` em `app/models/link.rb`. A linha é portanto sempre inserida com a
coluna ainda a NULL, que é a razão pela qual tem de continuar nullable — o
`db/schema.rb` e as migrations concordam nisto. Repara na consequência: os
códigos são sequenciais e enumeráveis (ver Próximos Passos).

O `UrlValidator` (`app/validators/url_validator.rb`) restringe o `url` a URLs
absolutos `http`/`https` com host. Isto é um controlo de segurança, não
formatação: sem ele um encurtador guarda e devolve alegremente um URL
`javascript:` ou `data:`, transformando cada link curto num potencial vetor de
XSS para quem lhe clica. Faz parse com `URI` em vez de uma regex.

## Stack

| Componente | Versão |
|---|---|
| Ruby | 3.4.x (ver `.ruby-version`) |
| Rails | 8.1.x |
| PostgreSQL | 17 |
| Redis | 8 |
| Sidekiq | 8.x |
| Puma | 8.x |

## Arranque Rápido

```bash
git clone <repo> link_pulse
cd link_pulse
bash scripts/rename_project.sh o_teu_projeto   # também cria o .env
docker compose up --build
```

É só isto — o entrypoint espera pelo PostgreSQL e corre `rails db:prepare`, que
é idempotente e faz o que é preciso em cada arranque:

| Estado | Ação |
|---|---|
| Base de dados inexistente | Cria-a, carrega o `db/schema.rb`, **corre os seeds** |
| Migrations pendentes | Corre só as migrations |
| Tudo em dia | Não faz nada |

Sem ficheiros de marcação, sem passos manuais. Para saltar isto num container
específico (o serviço sidekiq já o faz), define `SKIP_DB_PREPARE=true`.

Se saltares o rename, copia primeiro o ficheiro de ambiente:

```bash
cp .env.example .env
docker compose up --build
```

URL da app: `http://localhost:3000`
Health: `http://localhost:3000/health`
UI do Mailpit: `http://localhost:8025`
UI do Sidekiq: `http://localhost:3000/sidekiq`

## Script de Rename

Deteta o nome atual do projeto automaticamente (funciona mesmo depois de
renames anteriores) e atualiza todas as referências (`link_pulse`, `LinkPulse`,
`Link Pulse`):

```bash
bash scripts/rename_project.sh novo_nome            # interativo
bash scripts/rename_project.sh novo_nome --yes      # sem confirmação
bash scripts/rename_project.sh novo_nome --dry-run  # só pré-visualiza
```

## Comandos Comuns

Base de dados:

```bash
docker compose run --rm rails rails db:prepare
docker compose run --rm rails rails db:migrate
docker compose run --rm rails rails db:rollback
docker compose run --rm rails rails db:seed
```

Rails CLI:

```bash
docker compose run --rm rails rails console
docker compose run --rm rails rails routes
docker compose run --rm rails rails generate model Article title:string body:text
```

Testes e qualidade:

```bash
docker compose run --rm -e SKIP_DB_PREPARE=true rails bundle exec rspec
docker compose run --rm -e SKIP_DB_PREPARE=true rails bundle exec rubocop
docker compose run --rm -e SKIP_DB_PREPARE=true rails bundle exec brakeman
```

Logs e shell:

```bash
docker compose logs -f rails
docker compose logs -f sidekiq
docker compose exec rails bash
```

## Testes e Qualidade

RSpec + FactoryBot + Shoulda Matchers, com o DatabaseCleaner a tratar do
isolamento (o `use_transactional_fixtures` está desligado). 41 exemplos, a
cobrir os modelos `Link` e `ClickEvent`, os dois controllers e o endpoint de
health.

A configuração do FactoryBot, DatabaseCleaner e Shoulda vive nos
`spec/support/*.rb`. Não a dupliques no `spec/rails_helper.rb` — um segundo
`around(:each) { DatabaseCleaner.cleaning }` envolve cada exemplo em dois blocos
de limpeza aninhados.

O `config.action_controller.allow_forgery_protection = false` está definido em
`config/environments/test.rb`. Os request specs não levam token CSRF, por isso
sem isto todos os specs de `POST`/`DELETE` devolvem 422.

**RuboCop.** O `app/components/**` está excluído dos cops estruturais
(`Metrics`, `Layout/LineLength`, `Lint/DuplicateBranch`, `Style/HashLikeCase`):
esses ficheiros são vendored do Rails Blocks, e reformatá-los tornaria mais
difícil integrar atualizações do upstream. As regras de nomes e de aspas
continuam a aplicar-se lá. O `Metrics/MethodLength` e o `Metrics/AbcSize` estão
subidos para 15 e 20, porque os valores por omissão são mais apertados do que o
estilo em que este código está escrito.

**Brakeman** reporta um aviso fraco — o redirect com `allow_other_host` no
`RedirectsController`. Redirecionar para um URL externo fornecido pelo
utilizador é o propósito inteiro de um encurtador; o risco que ele assinala é
tratado na escrita pelo `UrlValidator`, que torna impossível persistir um
esquema hostil.

## Adicionar Dependências

### JavaScript (importmap — sem Node/npm)

Os pacotes JS são geridos com importmap e vendored para `vendor/javascript`:

```bash
docker compose exec rails bin/importmap pin lodash        # adicionar
docker compose exec rails bin/importmap unpin lodash      # remover
docker compose exec rails bin/importmap outdated          # ver atualizações
docker compose exec rails bin/importmap update            # atualizar pins
```

Os pins ficam registados em `config/importmap.rb` e são commitados com o
ficheiro vendored — sem build step, sem `node_modules`. Se mais tarde
precisares de bundling a sério (React, TypeScript), muda para jsbundling:
`bundle add jsbundling-rails` e `rails javascript:install:esbuild`.

### Gems Ruby

```bash
docker compose exec rails bundle add <gem>   # atualiza Gemfile + Gemfile.lock
docker compose restart rails sidekiq
```

As gems vivem no volume `bundle_cache`, por isso não é preciso rebuild da imagem
em desenvolvimento. Faz rebuild (`docker compose build`) quando quiseres que
fiquem embutidas na imagem.

### Pacotes de sistema (vim, htop, ...)

Tudo o que o container precisa vive na imagem — nada é instalado em runtime.
Adiciona os pacotes à lista do `apt-get install` no Dockerfile:

- stage `development` → ferramentas só de dev (vim, git, less e zsh já lá estão)
- stage `base` → bibliotecas de runtime necessárias também em produção

Depois faz rebuild: `docker compose build`.

## Desenvolvimento Local (sem Docker)

Precisa de Ruby (ver `.ruby-version`), PostgreSQL e Redis a correr localmente:

```bash
bin/setup
bin/dev   # web + sidekiq via overmind/foreman (cai no rails server)
```

## Compose de Produção

Build e arranque:

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml build
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

As migrations correm automaticamente no arranque, via entrypoint (`db:prepare`).
A imagem de produção é mínima: só gems de produção, assets pré-compilados,
utilizador não-root, jemalloc ativo.

Variáveis de ambiente obrigatórias em produção:

```bash
SECRET_KEY_BASE=<openssl rand -hex 64>
POSTGRES_USER=<utilizador_seguro>
POSTGRES_PASSWORD=<password_forte>
POSTGRES_DB=link_pulse_production
REDIS_PASSWORD=<password_redis>
REDIS_URL=redis://:<password_redis>@redis:6379/0
ALLOWED_HOSTS=odominio.com
SMTP_HOST=smtp.sendgrid.net
SMTP_PASSWORD=<api_key>
ACTIVE_STORAGE_SERVICE=amazon
SIDEKIQ_USERNAME=<utilizador_sidekiq>
SIDEKIQ_PASSWORD=<password_sidekiq>
```

Há também um script de deploy guiado (backup, build, migrate, health check):

```bash
bash docker/scripts/deploy.sh
```

## CI

Workflow do GitHub Actions (`.github/workflows/ci.yml`):

1. **Lint & Security** — RuboCop, Brakeman, bundler-audit
2. **RSpec** — suite completa contra PostgreSQL 17 + Redis 8
3. **Docker Build** — build da imagem de produção no `main`

A versão de Ruby é lida do `.ruby-version` em todo o lado (Gemfile, CI, Docker).

## Resolução de Problemas

**O Postgres não arranca depois de uma atualização de versão maior** (por
exemplo, volumes criados com postgres 16 e o compose agora usa 17): o formato do
diretório de dados é incompatível. Se os dados forem descartáveis, faz reset aos
volumes:

```bash
docker compose down -v
docker compose up --build
```

Caso contrário, faz dump com a imagem antiga (`pg_dump`) e restaura depois de
atualizar.

**Porta já em uso**: sobrepõe `APP_PORT`, `POSTGRES_PORT` ou `REDIS_PORT` no
`.env`.

**Forçar um reset completo da base de dados** (só em desenvolvimento):

```bash
docker compose run --rm rails rails db:reset_and_seed
```

## Próximos Passos

Lacunas conhecidas, mais ou menos por ordem de valor:

- **Sem autenticação nem ownership.** O `bcrypt` está no Gemfile mas não existe
  modelo `User`. Todos os links são globais e o dashboard é completamente
  público.
- **Os short codes são enumeráveis.** O `short_code` é o id do registo em
  base62, por isso qualquer pessoa pode percorrer `/l/1`, `/l/2`, … e descobrir
  todos os links da base de dados. Corrigir isto implica gerar o código
  aleatoriamente, o que por sua vez obriga a tratar colisões — o índice único já
  serve de garantia.
- **Os cliques são registados de forma síncrona no caminho do redirect.** O
  `RedirectsController#show` faz INSERT de um `ClickEvent` antes de
  redirecionar, no caminho mais quente da app. O Sidekiq está todo configurado
  (Procfile, serviço no compose, Web UI) mas o `app/jobs/` não tem um único job.
- **Os cliques não guardam metadados.** O `ClickEvent` só tem `link_id` e
  timestamps, por isso qualquer coisa mais rica do que contagens — referrer,
  país, user agent, séries temporais — precisa primeiro de uma migration.
- **Sem gestão de links.** Os links podem ser criados mas não editados nem
  apagados, e não há aliases personalizados, datas de expiração, páginas por
  link nem códigos QR.
- **O componente Modal está inacabado.** O `Modal::Component` aceita um `title:`
  que nunca é renderizado, o id do dialog está fixo em `add-item-modal` (por
  isso dois modais na mesma página colidem), e o botão de fechar não tem
  `aria-label` — botões só de ícone não expõem nome acessível.
- **Sem specs de componentes.** O `spec/components/` não existe e o
  `view_component/test_helper` não é carregado no `spec/rails_helper.rb`, por
  isso os componentes em `app/components/` não estão testados.
- **Referências mortas.** O `_table.html.erb` passa `frame_id: "items-frame"` ao
  componente de paginação, mas não existe nenhum turbo frame com esse id. O
  `Navbar::Component` está inteiramente construído e não é renderizado em lado
  nenhum — o `shared/_navbar.html.erb` são três linhas com um logo. O layout e o
  `config/importmap.rb` puxam Shoelace, Tom Select, Air Datepicker e Photoswipe
  de CDNs; só o Shoelace é mesmo necessário, e apenas para o fundo da página
  (`sl-theme-dark` no `<html>`).
- **Texto misturado PT/EN.** O texto de ajuda e o placeholder do formulário do
  modal estão em português enquanto o resto da UI está em inglês, e o botão de
  fechar do flash tem `aria-label="Fechar"`. O `config/locales/en.yml` só está
  ligado aos cards de estatísticas do dashboard.

### Nota: atualizações do dashboard em tempo real

Atualizar o dashboard quando alguém clica num link curto não pode ser feito a
partir da resposta a esse pedido — o visitante é uma sessão de browser
diferente. Requer broadcast por Action Cable (o Redis já está configurado).

Três restrições, se isto alguma vez avançar:

1. **Fazer broadcast a partir de um job, não do `RedirectsController`.** O
   redirect é o caminho mais quente da app; renderizar e empurrar HTML aí atrasa
   o visitante em benefício de outra pessoa. O Sidekiq já está disponível.
2. **Os broadcasts não têm contexto de request.** Tudo o que dependa do
   `request` — os links de paginação em particular — vai renderizar mal ou
   falhar. Fazer broadcast só dos cards, não da tabela paginada.
3. **Limitar a frequência.** Um broadcast por clique inunda o socket num link
   popular, para atualizar um número que ninguém lê a essa resolução.

Isto é um extra, não um requisito: recarregar a página já mostra os números
corretos.

## Licença

MIT
