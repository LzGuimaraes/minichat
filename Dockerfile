# syntax=docker/dockerfile:1

# Imagem base: Node 20 LTS (mínimo exigido pelo Next.js 16 é 20.9)
# Alpine é suficiente aqui porque o projeto não tem dependências nativas
# (o SQLite é o sql.js, compilado para WebAssembly).
FROM node:20-alpine

WORKDIR /app
ENV NODE_ENV=production

# 1. Dependências (inclui devDependencies, necessárias para o build)
COPY package.json package-lock.json ./
RUN npm ci

# 2. Código-fonte e build de produção
COPY . .
RUN npm run build

# 3. Usuário sem privilégios e diretório persistente de dados
RUN addgroup --system --gid 1001 nodejs \
 && adduser --system --uid 1001 nextjs \
 && mkdir -p /data \
 && chown -R nextjs:nodejs /app /data

USER nextjs

EXPOSE 25000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD wget -qO- http://127.0.0.1:25000/ >/dev/null 2>&1 || exit 1

# next start já lê a porta 25000 (script "start" do package.json)
CMD ["node_modules/.bin/next", "start", "-p", "25000"]
