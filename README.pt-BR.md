# DashCat

Um aplicativo leve para a barra de menus do macOS que combina histórico da área de transferência, monitoramento do sistema, prevenção de suspensão e inversão da roda do mouse em um gato que corre.

[中文](README.md) | [English](README.en.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt-BR.md) | [Italiano](README.it.md) | [繁體中文](README.zh-TW.md) | [Русский](README.ru.md)

---

Eu tinha várias ferramentas rodando na barra de menus do macOS: uma para carga do sistema, outra para histórico da área de transferência (Maccy), outra para prevenir suspensão (Caffeine) e mais uma solução para a direção da roda de um mouse externo. Vários ícones, vários processos em segundo plano — parecia um desperdício. Então criei uma do zero, mantendo apenas o essencial: monitoramento do sistema, gerenciamento da área de transferência, prevenção de suspensão e inversão da roda do mouse. O monitor é otimizado para Apple Silicon, o gerenciador da área de transferência é enxuto e eficiente, e a prevenção de suspensão junto com a inversão da roda estão integradas. Justo o necessário, nada mais.

Assim nasceu o DashCat. Um gato na barra de menus — quanto mais rápido ele corre, maior é a carga; clique esquerdo para histórico da área de transferência com busca instantânea; clique direito para prevenção de suspensão, direção da roda do mouse, modo de monitoramento e troca de idioma. Um ícone cobre várias ferramentas do dia a dia. Zero dependências, uso mínimo de recursos, todos os dados armazenados localmente.

---

## Funcionalidades

- **Gerenciador de Área de Transferência**
  - Clique esquerdo no ícone do gato para abrir o painel de histórico da área de transferência
  - Filtragem de busca em tempo real
  - Clique para copiar, `Option + Enter` para copiar como texto simples
  - Clique com o botão direito em um item para fixá-lo no topo
  - Suporte a texto e imagens (imagens comprimidas em JPEG, armazenamento de imagens opcional)
  - Retenção personalizável: 7 / 14 / 30 / 90 dias, para sempre, ou um valor personalizado de 1-365 dias
  - Todos os dados armazenados localmente — totalmente offline, sem coleta de dados

- **Monitor do Sistema**
  - Três modos de monitoramento: Combinado, CPU, Memória
  - A velocidade da animação do gato reflete a carga do sistema em tempo real — quanto mais rápido corre, maior a pressão
  - O modo combinado escolhe automaticamente o maior valor entre CPU e memória para a animação
  - A exibição Dois valores mostra porcentagens C/M compactas em duas linhas
  - Modos de exibição: porcentagem e animação, apenas animação, apenas porcentagem ou dois valores

- **Prevenção de Suspensão**
  - Cor padrão: normal — o sistema pode suspender
  - Azul: impedir suspensão por inatividade do sistema (a tela ainda pode desligar)
  - Laranja: impedir que a tela desligue
  - Alternar diretamente do menu de contexto — a cor do gato muda em tempo real

- **Mais**
  - 11 idiomas: English, 中文, 日本語, 한국어, Deutsch, Français, Español, Português, Italiano, 繁體中文, Русский
  - Inverter a roda de um mouse externo mantendo a rolagem natural do macOS no trackpad
  - Suporte para iniciar ao fazer login
  - Eficiente: limite de animação de 12 fps, intervalo de amostragem de 5 s, pausa automática na suspensão do sistema
  - Zero dependências externas — AppKit + Swift puro

## Requisitos

- macOS 13 (Ventura) ou posterior
- Mac com Apple Silicon (chips da série M)

## Instalação

**Opção 1: Instalador DMG**

1. Vá para a página [Releases](../../releases) e baixe o último `DashCat-<versão>.dmg`
2. Abra o DMG e arraste DashCat para sua pasta Aplicativos
3. Na primeira execução, o macOS pode mostrar "o aplicativo está danificado" ou "não foi possível verificar o desenvolvedor" — isso é o Gatekeeper bloqueando um aplicativo não assinado; o aplicativo está íntegro. Execute o seguinte comando no Terminal para remover a quarentena:
   ```bash
   xattr -cr /Applications/DashCat.app
   ```
   Depois clique duas vezes para iniciar normalmente. Alternativamente, clique direito → Abrir → clique em Abrir no diálogo.

**Opção 2: Compilar do código-fonte (sem necessidade de contornar o Gatekeeper)**

1. Clone este repositório
2. Abra `DashCat.xcodeproj` no Xcode
3. Selecione sua própria conta de desenvolvedor em **Signing & Capabilities**
4. Execute com `⌘R` — o Xcode assina o aplicativo automaticamente

## Uso

- **Clique esquerdo** no ícone do gato: abrir painel de histórico da área de transferência
  - Digite na caixa de busca para filtrar
  - Clique em um item para copiá-lo
  - `Option + Enter` para copiar como texto simples
  - Clique com o botão direito em um item para fixar ou desafixar
- **Clique direito** no ícone do gato: abrir menu de configurações
  - Alternar modo de monitoramento, modo de prevenção de suspensão
  - Gerenciar histórico da área de transferência (salvar imagens, dias de retenção, limpar histórico)
  - Inverter roda do mouse, mudar idioma, alternar modo de exibição, configurar início ao fazer login

## Perguntas Frequentes

**Onde os dados da área de transferência são armazenados?**

`~/Library/Application Support/DashCat/` — `clipboard.db` para registros de texto, `Images/` para arquivos de imagem. Limpar o histórico limpa ambos.

**Quanto espaço em disco as imagens usam?**

As imagens são armazenadas como JPEG (algumas centenas de KB cada). O salvamento de imagens está desativado por padrão. Quando ativado, há um limite total de 500 MB — as imagens não fixadas mais antigas são excluídas automaticamente quando o limite é atingido.

**O que significam as cores do gato?**

Padrão → comportamento normal de suspensão. **Azul** → impedindo suspensão do sistema. **Laranja** → impedindo suspensão da tela. Alterne pelo menu de contexto.

**Por que inverter a roda do mouse exige permissão de Acessibilidade?**

O DashCat precisa identificar eventos da roda do mouse no fluxo de eventos do sistema e inverter sua direção, por isso o macOS exige permissão de Acessibilidade. Sem ela, o histórico da área de transferência, o monitoramento do sistema e a prevenção de suspensão continuam funcionando; o menu de contexto mostra um aviso e um atalho para os Ajustes do Sistema.

**Suporta Macs com Intel?**

Não. Apenas arm64, projetado para Apple Silicon.

**Como isso difere do Maccy / CopyClip / Amphetamine?**

O DashCat combina gerenciamento da área de transferência (como Maccy), monitoramento do sistema e prevenção de suspensão (como Amphetamine / Caffeine) em um único aplicativo leve da barra de menus — um ícone, um processo, zero dependências. AppKit puro para uso mínimo de memória.

**Por que o macOS diz que o aplicativo está "danificado" ou "não foi possível verificar o desenvolvedor" na primeira execução?**

O binário pré-compilado não é assinado com um certificado de desenvolvedor Apple, então o Gatekeeper mostra esta mensagem — o aplicativo está íntegro. Execute `xattr -cr /Applications/DashCat.app` no Terminal para remover a quarentena, depois inicie normalmente. Para evitar completamente esta etapa, compile do código-fonte e assine com sua própria conta.

## Licença

MIT License
