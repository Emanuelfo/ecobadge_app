# EcoBadge App

O **EcoBadge** é um aplicativo mobile desenvolvido com Flutter que tem como objetivo incentivar o consumo consciente por meio da análise de produtos. Através de um sistema de escaneamento de código de barras, o app avalia o nível de sustentabilidade de um item e engaja o usuário com recursos interativos e gamificados.

---

## Funcionalidades

### Scanner (Principal)

* Leitura de código de barras utilizando a câmera
* Exibição do código escaneado
* Simulação de informações do produto
* Cálculo de uma pontuação de sustentabilidade (**EcoPoint**)

---

### Comunidade

* Feed com conteúdos sobre sustentabilidade
* Dicas, notícias e curiosidades
* Interface inspirada em redes sociais

---

### Games

* Quizzes e missões interativas
* Sistema de pontuação (+ pontos por atividades)
* Experiência gamificada

---

### Cupons

* Exibição de pontos acumulados
* Lista de recompensas simuladas
* Sistema de troca por cupons fictícios

---

## Design

O aplicativo segue uma identidade visual moderna, amigável e levemente lúdica.

### Paleta de cores:

* Verde: `#9BA960`
* Cinza escuro: `#4C4C4C`
* Marrom: `#835646`
* Bege claro: `#C4D18B`
* Marrom claro: `#AD705A`

---

## Tecnologias utilizadas

* **Flutter**
* **Dart**
* **Material Design**
* Biblioteca **mobile_scanner** (leitura de código de barras)

---

## Arquitetura

* Código estruturado em widgets separados
* Interface responsiva
* Organização focada em escalabilidade
* Código comentado para fácil entendimento

---

## Como executar o projeto

### 1. Clone o repositório

```bash
git clone <url-do-repositorio>
cd ecobadge
```

### 2. Instale as dependências

```bash
flutter pub get
```

### 3. Execute o app

```bash
flutter run
```

---

## Gerar APK

```bash
flutter build apk
```

O arquivo será gerado em:

```
build/app/outputs/flutter-apk/app-release.apk
```

---

## Objetivo do projeto

O EcoBadge foi desenvolvido como um protótipo funcional com foco em:

* Sustentabilidade 
* Consumo consciente 
* Engajamento do usuário 
* Experiência mobile moderna 

---

## Possíveis melhorias futuras

* Integração com APIs reais de produtos
* Sistema de login/autenticação
* Banco de dados para comunidade
* Parcerias reais para cupons
* Ranking de usuários

---

## Autor

Desenvolvido como projeto para participação de olimpíadas: ONDA e OBT

