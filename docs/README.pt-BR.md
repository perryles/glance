<h1 align="center">
  <br>
  <a href="https://tryglance.app"><img src="../glance/Assets.xcassets/appicon.imageset/appicon.png" alt="Glance" width="150"></a>
  <br>
  Glance
  <br>
</h1>

<h3 align="center">Desbloqueie seu Mac com o rosto</h3>

<p align="center">
  <a href="../README.md" lang="en">English</a> ·
  <a href="README.zh-CN.md" lang="zh-CN">简体中文</a> ·
  <a href="README.ja.md" lang="ja">日本語</a> ·
  <a href="README.es.md" lang="es">Español</a> ·
  <a href="README.fr.md" lang="fr">Français</a> ·
  <a href="README.de.md" lang="de">Deutsch</a> ·
  <a href="README.pt-BR.md" lang="pt-BR">Português (Brasil)</a> ·
  <a href="README.tr.md" lang="tr">Türkçe</a>
</p>

<p align="center">
  <a href="../LICENSE"><img src="https://img.shields.io/badge/license-MIT-black.svg" alt="Licença MIT"></a>
  <img src="https://img.shields.io/badge/macOS-15%2B-black.svg" alt="macOS 15+">
  <img src="https://img.shields.io/badge/Swift-SwiftUI-black.svg" alt="Swift">
</p>

O Glance traz para o Mac uma experiência semelhante ao Face ID do iPhone. Desbloqueie seu Mac com um olhar, sem digitar nem procurar a tecla Touch ID. Tudo é executado no próprio dispositivo com os frameworks Vision e Core ML da Apple, de modo que seus dados faciais e sua senha do Mac nunca são enviados à internet. A interface se integra ao recorte da tela do MacBook com animações fluidas no estilo da Dynamic Island.

https://github.com/user-attachments/assets/77438826-80a9-4ab2-9fc3-42407a2d0adb

---

> [!WARNING]
> ## Leia antes de baixar
> ## O Glance é menos seguro que o Face ID ou o Touch ID da Apple
>
> Os MacBooks não possuem os sensores de profundidade que tornam o Face ID do iPhone confiável e seguro. Um iPhone cria um mapa 3D do seu rosto, enquanto a webcam do MacBook captura uma imagem plana em 2D. Isso implica as seguintes limitações.
>
> - O Glance consegue rejeitar, com confiança razoável, uma foto impressa ou uma foto exibida na tela de um celular (a detecção de vivacidade de nível alto precisa estar ativada).
> - O Glance não rejeita de forma confiável um vídeo seu.
> - O macOS não oferece uma API que permita a um aplicativo de terceiros autorizar o login. Por isso, o Glance desbloqueia o Mac digitando sua senha armazenada na tela de bloqueio.
>
> O Glance oferece conveniência, não um aumento de segurança. Continue apenas se aceitar essa troca.

## Instalação

**Requisitos**

- macOS 15 Sequoia ou posterior
- Mac com Apple Silicon ou Intel

<a href="https://github.com/perryles/glance/releases/latest/download/Glance-1.2.1.dmg" target="_self"><img width="200" src="https://github.com/user-attachments/assets/cdb8af97-1ee2-4669-b7cb-dcfb56c9dd61" alt="Baixar para Mac" /></a>

Abra o arquivo `.dmg`, arraste o Glance para `/Applications` e abra o aplicativo.

## Permissões

| Permissão | Finalidade |
|---|---|
| **Câmera** | Para detectar seu rosto. Os quadros são processados na memória e nunca são gravados no disco. |
| **Acessibilidade** | Para digitar sua senha na tela de bloqueio. |
| **Touch ID** | Protege o acesso à chave que criptografa seus dados faciais e sua senha. |

## Como funciona

1. Abra o aplicativo e siga a configuração inicial para cadastrar seu rosto. O Glance orienta a captura enquanto você vira a cabeça em nove direções. Cada quadro se torna um *vetor de características* de 512 números, uma impressão digital matemática, e a imagem é descartada.
2. Digite sua senha do Mac uma vez. Ela é criptografada e protegida pelo Touch ID.
3. Quando seu Mac é bloqueado ou sai do repouso, a animação aparece no recorte da tela e começa a procurar um rosto.
4. Se o rosto corresponder ao seu e as verificações de vivacidade confirmarem que você é uma pessoa real, o Glance digita a senha e desbloqueia o Mac.

## Recursos

| Recurso | Descrição |
|---|---|
| **Desbloqueio facial** | É acionado ao sair do repouso, ao bloquear ou ao pressionar espaço na tela de bloqueio. Você pode combinar essas opções livremente. |
| **Várias identidades** | Cadastre várias pessoas ou diferentes aparências suas, com óculos, barba ou iluminação diferente. Cada identidade pode ser desativada sem ser excluída. |
| **Detecção de vivacidade** | Analisa movimentos e reflexos para distinguir um rosto real de uma foto. Permite escolher um nível baixo, alto ou desativar a detecção. |
| **Interface no recorte da tela** | Uma cápsula se expande em uma animação de leitura, com estados de sucesso e falha. Passe o cursor sobre ela para tentar novamente ou desative todas as animações para manter o Glance invisível. |
| **Câmera e tela** | Escolha a câmera a ser usada, inclusive câmeras diferentes para a tela integrada e um monitor externo. |
| **Bloqueio automático de sessões** | A sessão do Touch ID é bloqueada novamente após o período de inatividade escolhido, para que um Mac sem supervisão não fique autorizado indefinidamente. |
| **Resposta tátil do trackpad** | Passar o cursor sobre o recorte da tela aciona uma resposta tátil. |
| **Suporte a Macs sem recorte na tela** | Nos Macs sem recorte, é exibida uma interface em forma de cápsula no estilo da Dynamic Island. |
| **Controle dos seus dados** | Edite ou exclua seus cadastros faciais ou sua senha armazenada a qualquer momento. Os arquivos criptografados correspondentes são removidos imediatamente. |

---

# Privacidade e segurança

O Glance foi projetado para manter os dados biométricos e as credenciais no dispositivo.

### Dados faciais

O Glance nunca armazena imagens da câmera. Durante o cadastro, cada rosto capturado é convertido em um **vetor de características de 512 dimensões** por um modelo Core ML baseado em ArcFace. O quadro original é descartado em seguida.

Os vetores são armazenados localmente e criptografados com **AES-GCM**.

### Credenciais

Sua senha do Mac é armazenada como dados criptografados e nunca é gravada no disco em texto simples. A chave de criptografia é uma **chave AES de 256 bits armazenada nas Chaves do macOS**, protegida por `userPresence`, que exige Touch ID ou a senha do dispositivo.

A chave só permanece na memória enquanto uma sessão autorizada do Glance está ativa.

### Processo de desbloqueio

Para que o Glance digite sua senha, todas as condições a seguir precisam ser atendidas.

1. Uma sessão válida do Glance está autorizada.
2. O Mac está realmente na tela de bloqueio.
3. Uma identidade ativada supera o limite de similaridade configurado.
4. O rosto detectado passa nas verificações de vivacidade.
5. A permissão de acessibilidade está disponível para inserir a senha.

O reconhecimento facial e a detecção de vivacidade são executados de forma independente e ambos precisam ter sucesso antes de a senha ser inserida.

### Processamento local

O reconhecimento facial, o cadastro de rostos e a detecção de vivacidade são executados inteiramente no dispositivo com Vision e Core ML. O Glance não envia dados faciais, quadros da câmera ou credenciais a um servidor.

### Como distingue um rosto de uma foto

Cinco sinais independentes são analisados em uma janela deslizante de aproximadamente 2 segundos, com duas funções.

- **Sinais de rejeição** indicam uma tentativa de fraude, como reflexos de tela ou um retângulo com formato de dispositivo ao redor do rosto. Qualquer um deles faz a leitura falhar imediatamente e prevalece sobre os demais resultados.
- **Sinais de confirmação** indicam um rosto real, como a geometria plana ou tridimensional dos pontos faciais, a paralaxe do nariz ao virar a cabeça e as piscadas. Qualquer um é suficiente. A ausência deles nunca representa uma falha por si só, pois uma pessoa real pode ficar parada sem piscar.

O nível baixo usa apenas sinais de rejeição. O nível alto usa sinais de rejeição e de confirmação.

### Face Lab

O Face Lab é um console de depuração oculto para testar o reconhecimento facial e a detecção de vivacidade com valores reais.

Para abri-lo, vá a Ajustes → Sobre e clique cinco vezes no ícone do aplicativo. Uma seção de depuração aparecerá na barra lateral.

---

## Compilar a partir do código-fonte

### Pré-requisitos

- macOS 15+
- Xcode 26+
- Python 3.9+ e Git, com acesso à rede para o primeiro download das dependências

### Etapas de compilação

1. Clone este fork e abra o projeto.

   ```bash
   git clone https://github.com/perryles/glance.git
   cd glance
   open glance.xcodeproj
   ```

2. Selecione o target e o esquema `glance`. Em **Signing & Capabilities**, escolha sua equipe de desenvolvimento Apple e ative a assinatura automática. Use `glance/glance.entitlements` para configurar a câmera e o acesso protegido às Chaves.

3. Escolha **My Mac** como destino e pressione `Cmd + R`. A primeira compilação assinada baixa versões fixas dos fontes de libusb/libuvc e inclui automaticamente o serviço auxiliar de infravermelho.

Para instalar uma versão de desenvolvimento separadamente, você pode usar seu próprio Bundle Identifier. Credenciais e cadastros faciais são isolados por identificador. As atualizações automáticas são desativadas para Bundle Identifiers personalizados.

Consulte o guia de infravermelho para configuração e opções de compilação, incluindo `GLANCE_ENABLE_INFRARED=NO`. [IR](../tools/infrared/README.md)

## Contribuições

PRs para correções, funcionalidades, traduções e documentação são bem-vindos. Direcione-os à branch `main` de `perryles/glance` e descreva as alterações e como foram verificadas. [Abrir um Pull Request](https://github.com/perryles/glance/compare)

Relate erros e sugira funcionalidades pelo GitHub Issues. [Issues](https://github.com/perryles/glance/issues)

## Agradecimentos

- Agradecemos a Jonathan Zhou e aos colaboradores do Glance pelo aplicativo original. [jonnyoo/glance](https://github.com/jonnyoo/glance)
- Agradecemos a JediBrooker pela implementação de infravermelho BRIO no PR #50. [PR #50](https://github.com/jonnyoo/glance/pull/50)
- **[The Boring Notch](https://github.com/TheBoredTeam/boring.notch)** — pela física da janela no recorte da tela.
- **[InsightFace](https://github.com/deepinsight/insightface)** — pelo modelo ArcFace usado no reconhecimento.
- **[Alcove](https://tryalcove.com)** — pela grande inspiração de design.
- Agradecemos ao Sparkle pelas atualizações do aplicativo. [Sparkle](https://github.com/sparkle-project/Sparkle)
- Agradecemos a libusb e libuvc pela captura USB de infravermelho. [libusb](https://github.com/libusb/libusb), [libuvc](https://github.com/libuvc/libuvc)

## Licença

O código-fonte do projeto é distribuído sob a licença MIT. Obra original © 2026 Jonathan Zhou. Contribuições ao fork © 2026 perryles e colaboradores. [MIT](../LICENSE)

Bibliotecas de terceiros e pesos de modelos têm suas próprias licenças. O InsightFace estabelece uma licença de pesquisa não comercial para seus modelos pré-treinados. [Licenciamento do InsightFace](https://github.com/deepinsight/insightface#license)

As compilações assinadas com infravermelho incluem as licenças nativas em `Contents/Resources/InfraredLicenses` e os fontes e materiais para refazer a vinculação em `Contents/Resources/InfraredSources.zip`.
