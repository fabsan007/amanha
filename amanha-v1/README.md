# AMANHÃ v1.0 — protótipo funcional

## Publicar agora pelo Netlify Drop
1. Descompacte `amanha-v1.zip`.
2. Acesse https://app.netlify.com/drop.
3. Arraste a **pasta `amanha-v1`** (que contém `index.html`, `styles.css` e `app.js`) para a área de publicação.
4. Abra o endereço fornecido e teste o questionário no celular e computador.

## Publicar pelo GitHub + Netlify
1. Crie um repositório privado no GitHub e envie os três arquivos da pasta.
2. No Netlify, escolha Add new project > Import an existing project > GitHub.
3. Selecione o repositório; para este site estático, deixe Build command vazio e Publish directory como `.`.
4. Publique. Atualizações futuras podem ser feitas por commits no GitHub.

## O que funciona
- Site responsivo com identidade azul profundo, branco e dourado.
- Questionário em três etapas com validação.
- Cinco jornadas por momento de vida.
- Cálculo de saldo mensal, meses de reserva e dívidas declaradas.
- Recomendações e plano de ação inicial de 30 dias.
- Impressão ou exportação via impressão do navegador.

## Limites importantes
- Esta versão é **demonstração funcional**, sem login, banco de dados, painel administrativo, pagamento ou IA.
- **Não está conectada ao Supabase.** A integração será feita na próxima versão, com autenticação e políticas de segurança adequadas.
- Os dados digitados não são transmitidos nem armazenados pelo código desta versão; permanecem na memória da página até recarregar ou sair. Não use dados pessoais reais ou confidenciais durante testes em computadores compartilhados.
- Os cálculos são simplificados e não substituem aconselhamento profissional.
- Para operar comercialmente com informações financeiras pessoais, implementar política de privacidade, segurança, autenticação e tratamento de dados conforme a LGPD.
