<h1 align="center">
  <br>
  <a href="https://tryglance.app"><img src="../glance/Assets.xcassets/appicon.imageset/appicon.png" alt="Glance" width="150"></a>
  <br>
  Glance
  <br>
</h1>

<h3 align="center">Déverrouillez votre Mac avec votre visage</h3>

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
  <a href="../LICENSE"><img src="https://img.shields.io/badge/license-MIT-black.svg" alt="Licence MIT"></a>
  <img src="https://img.shields.io/badge/macOS-15%2B-black.svg" alt="macOS 15+">
  <img src="https://img.shields.io/badge/Swift-SwiftUI-black.svg" alt="Swift">
</p>

Glance apporte à votre Mac une expérience similaire à Face ID sur iPhone. Déverrouillez votre Mac d'un regard, sans saisir de mot de passe ni chercher la touche Touch ID. Tout s'exécute sur l'appareil grâce aux frameworks Vision et Core ML d'Apple. Vos données faciales et votre mot de passe Mac ne sont jamais transmis sur Internet. L'interface s'intègre à l'encoche du MacBook avec des animations fluides inspirées de Dynamic Island.

https://github.com/user-attachments/assets/77438826-80a9-4ab2-9fc3-42407a2d0adb

---

> [!WARNING]
> ## À lire avant de télécharger
> ## Glance n'est pas aussi sécurisé que Face ID ou Touch ID d'Apple
>
> Les MacBook ne disposent pas des capteurs de profondeur qui rendent Face ID fiable et sûr sur iPhone. Un iPhone construit une carte 3D de votre visage, tandis que la webcam d'un MacBook voit une image plane en 2D. Cela implique les limites suivantes.
>
> - Glance peut rejeter, avec un degré de confiance raisonnable, une photo imprimée ou affichée sur l'écran d'un téléphone (la détection du vivant de niveau élevé doit être activée).
> - Glance ne rejette pas de manière fiable une vidéo de vous.
> - macOS ne fournit aucune API permettant à une application tierce d'autoriser une connexion. Glance déverrouille donc le Mac en saisissant votre mot de passe enregistré sur l'écran verrouillé.
>
> Glance apporte du confort, pas un renforcement de la sécurité. Continuez uniquement si vous acceptez ce compromis.

## Installation

**Configuration requise**

- macOS 15 Sequoia ou version ultérieure
- Mac avec puce Apple Silicon ou processeur Intel

<a href="https://github.com/perryles/glance/releases/latest/download/Glance-1.2.1.dmg" target="_self"><img width="200" src="https://github.com/user-attachments/assets/cdb8af97-1ee2-4669-b7cb-dcfb56c9dd61" alt="Télécharger pour Mac" /></a>

Ouvrez le fichier `.dmg`, faites glisser Glance dans `/Applications`, puis lancez l'application.

## Autorisations

| Autorisation | Utilité |
|---|---|
| **Caméra** | Pour détecter votre visage. Les images sont traitées en mémoire et ne sont jamais écrites sur le disque. |
| **Accessibilité** | Pour saisir votre mot de passe sur l'écran verrouillé. |
| **Touch ID** | Pour protéger l'accès à la clé qui chiffre vos données faciales et votre mot de passe. |

## Fonctionnement

1. Lancez l'application et suivez la configuration initiale pour enregistrer votre visage. Glance vous guide pour le capturer en tournant la tête dans neuf directions. Chaque image est convertie en un *vecteur de caractéristiques* de 512 nombres, une empreinte mathématique, puis l'image est supprimée.
2. Saisissez une fois votre mot de passe Mac. Il est chiffré et protégé par Touch ID.
3. Lorsque votre Mac se verrouille ou sort de veille, une animation apparaît dans l'encoche et la recherche d'un visage commence.
4. Si votre visage est reconnu et que la détection du vivant confirme votre présence réelle, Glance saisit le mot de passe et déverrouille le Mac.

## Fonctionnalités

| Fonctionnalité | Description |
|---|---|
| **Déverrouillage facial** | Se déclenche à la sortie de veille, au verrouillage ou en appuyant sur la barre d'espace sur l'écran verrouillé. Ces options peuvent être combinées librement. |
| **Plusieurs identités** | Enregistrez plusieurs personnes ou différentes apparences de vous-même, avec des lunettes, une barbe ou un éclairage différent. Chaque identité peut être désactivée sans être supprimée. |
| **Détection du vivant** | Analyse les mouvements et les reflets qui distinguent un vrai visage d'une photo. Niveau faible, élevé ou désactivé. |
| **Interface dans l'encoche** | Une capsule se déploie en animation de scan et indique la réussite ou l'échec. Survolez-la pour réessayer, ou désactivez entièrement les animations pour que Glance reste invisible. |
| **Caméra et écran** | Choisissez la caméra à utiliser, avec des caméras différentes pour l'écran intégré et un moniteur externe. |
| **Verrouillage automatique des sessions** | La session Touch ID se reverrouille après la durée d'inactivité choisie, afin qu'un Mac sans surveillance ne reste pas autorisé indéfiniment. |
| **Retour haptique du trackpad** | Le survol de l'encoche déclenche un retour haptique. |
| **Prise en charge des Mac sans encoche** | Sur les Mac sans encoche, une interface en forme de capsule inspirée de Dynamic Island est affichée. |
| **Maîtrise de vos données** | Modifiez ou supprimez vos enregistrements faciaux ou votre mot de passe enregistré à tout moment. Les fichiers chiffrés correspondants sont supprimés immédiatement. |

---

# Confidentialité et sécurité

Glance est conçu pour conserver les données biométriques et les identifiants sur l'appareil.

### Données faciales

Glance ne stocke jamais les images de la caméra. Lors de l'enregistrement, chaque visage capturé est converti en un **vecteur de caractéristiques à 512 dimensions** à l'aide d'un modèle Core ML fondé sur ArcFace. L'image d'origine est ensuite supprimée.

Les vecteurs sont stockés localement et chiffrés avec **AES-GCM**.

### Identifiants

Votre mot de passe Mac est enregistré sous forme chiffrée et n'est jamais écrit en clair sur le disque. La clé de chiffrement est une **clé AES de 256 bits stockée dans le trousseau macOS**, protégée par `userPresence`, qui exige Touch ID ou le mot de passe de l'appareil.

La clé reste en mémoire uniquement pendant qu'une session Glance autorisée est active.

### Processus de déverrouillage

Pour que Glance saisisse votre mot de passe, toutes les conditions suivantes doivent être remplies.

1. Une session Glance valide est autorisée.
2. Le Mac se trouve réellement sur l'écran verrouillé.
3. Une identité activée dépasse le seuil de similarité configuré.
4. Le visage détecté passe les contrôles de détection du vivant.
5. L'autorisation d'accessibilité nécessaire à la saisie du mot de passe est disponible.

La reconnaissance faciale et la détection du vivant s'exécutent indépendamment et doivent toutes deux réussir avant la saisie du mot de passe.

### Traitement local

La reconnaissance faciale, l'enregistrement des visages et la détection du vivant s'exécutent entièrement sur l'appareil avec Vision et Core ML. Glance n'envoie ni données faciales, ni images de la caméra, ni identifiants à un serveur.

### Distinguer un visage d'une photo

Cinq indices indépendants sont analysés sur une fenêtre glissante d'environ 2 secondes, avec deux rôles.

- **Les indices de rejet** révèlent une usurpation, comme des reflets d'écran ou un rectangle en forme d'appareil autour du visage. L'un ou l'autre fait immédiatement échouer le scan et prévaut sur tout autre résultat.
- **Les indices de confirmation** révèlent un vrai visage, comme la géométrie plane ou tridimensionnelle des points de repère faciaux, la parallaxe du nez lors des mouvements de tête et les clignements des yeux. Un seul suffit. Leur absence ne constitue jamais à elle seule un échec, puisqu'une personne réelle peut rester immobile sans cligner des yeux.

Le niveau faible utilise uniquement les indices de rejet. Le niveau élevé utilise les indices de rejet et de confirmation.

### Face Lab

Face Lab est une console de débogage cachée permettant de tester la reconnaissance faciale et la détection du vivant avec des valeurs réelles.

Pour l'ouvrir, allez dans Réglages → À propos, puis cliquez cinq fois sur l'icône de l'application. Une section de débogage apparaît dans la barre latérale.

---

## Compiler depuis les sources

### Prérequis

- macOS 15+
- Xcode 26+

### Étapes

1. Clonez le dépôt.

   ```bash
   git clone https://github.com/jonnyoo/glance.git
   cd glance
   ```

2. Ouvrez-le dans Xcode.

   ```bash
   open glance.xcodeproj
   ```

3. Cliquez sur le bouton d'exécution ou appuyez sur `Cmd + R`.

## Contributions

Les PR ne sont pas acceptées pour le moment. Vous pouvez créer un fork de ce projet.

Envoyez vos retours sur l'application à [tryglance.app/feedback](https://tryglance.app/feedback).

## Remerciements

- **[The Boring Notch](https://github.com/TheBoredTeam/boring.notch)** — pour la physique de la fenêtre de l'encoche.
- **[InsightFace](https://github.com/deepinsight/insightface)** — pour le modèle ArcFace utilisé pour la reconnaissance.
- **[Alcove](https://tryalcove.com)** — pour son importante inspiration graphique.

## Licence

[MIT](../LICENSE) © Jonathan Zhou
