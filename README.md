# 🏆 Minha Jornada — Gamifique sua rotina

App web para gamificar sua rotina diária, controlar tarefas por áreas da vida, metas anuais e leitura de livros.

**Acesse pelo celular de qualquer lugar após o deploy.**

---

## Stack

- **Next.js 14** — framework React
- **Supabase** — banco de dados PostgreSQL + autenticação
- **Vercel** — hospedagem gratuita
- **GitHub** — versionamento

---

## Passo a passo para colocar no ar

### 1. Supabase (banco de dados)

1. Acesse [supabase.com](https://supabase.com) e crie uma conta
2. Clique em **New Project**, dê um nome (ex: `minha-jornada`)
3. Aguarde o projeto ser criado (~2 min)
4. No menu lateral, vá em **SQL Editor**
5. Cole todo o conteúdo do arquivo `supabase-schema.sql` e clique **Run**
6. Vá em **Settings → API** e copie:
   - `Project URL` → vai virar `NEXT_PUBLIC_SUPABASE_URL`
   - `anon public` key → vai virar `NEXT_PUBLIC_SUPABASE_ANON_KEY`

### 2. GitHub (subir o código)

```bash
# No terminal, dentro da pasta do projeto:
git init
git add .
git commit -m "feat: minha jornada v1"

# Crie um repositório no github.com (pode ser privado)
# Depois cole os comandos que o GitHub mostrará:
git remote add origin https://github.com/SEU_USUARIO/minha-jornada.git
git push -u origin main
```

### 3. Vercel (deploy)

1. Acesse [vercel.com](https://vercel.com) e faça login com GitHub
2. Clique em **New Project** → importe o repositório `minha-jornada`
3. Na tela de configuração, adicione as variáveis de ambiente:
   - `NEXT_PUBLIC_SUPABASE_URL` = URL do Supabase
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY` = chave anon do Supabase
4. Clique em **Deploy**
5. Aguarde ~2 minutos → seu app estará em `https://minha-jornada.vercel.app`

### 4. Acessar pelo celular

1. Abra o link no Safari (iPhone) ou Chrome (Android)
2. No iPhone: toque em **Compartilhar → Adicionar à Tela de Início**
3. No Android: toque no menu **⋮ → Adicionar à tela inicial**
4. O app aparecerá como ícone na tela, igual a um app nativo

---

## Executar localmente (desenvolvimento)

```bash
# Instalar dependências
npm install

# Copiar variáveis de ambiente
cp .env.example .env.local
# Edite .env.local com seus dados do Supabase

# Rodar
npm run dev
# Acesse http://localhost:3000
```

---

## Funcionalidades

| Tela | O que faz |
|---|---|
| **Hoje** | Tarefas do dia organizadas por área, marcar feito/pulado com motivo, XP e streak |
| **Áreas** | Gerenciar as 6 áreas e adicionar novas tarefas com dias da semana |
| **Metas** | Metas anuais com progresso e métricas no final do ano |
| **Leituras** | Tracker de livros: meta de páginas/dia calculada automaticamente |
| **Métricas** | Análise de motivos de não conclusão, desempenho por área, semana/mês/ano |

---

## As 6 áreas pré-configuradas

- 📚 Estudos
- 💼 Trabalho  
- ✝️ Espiritual (Bíblia + devocional)
- 🏋️ Saúde Física
- 🧘 Saúde Mental
- 🎮 Lazer

---

## Sistema de XP e Níveis

- Cada tarefa concluída dá XP (você define quanto, padrão 10 XP)
- A cada 1.000 XP você sobe de nível
- Streak conta dias consecutivos com pelo menos 1 tarefa feita
- Os dados ficam salvos no Supabase, acessíveis de qualquer dispositivo
