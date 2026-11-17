<h1 align="center">
  <br>
  <a href="https://tryglance.app"><img src="../glance/Assets.xcassets/appicon.imageset/appicon.png" alt="Glance" width="150"></a>
  <br>
  Glance
  <br>
</h1>

<h3 align="center">Deinen Mac per Gesicht entsperren</h3>

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
  <a href="../LICENSE"><img src="https://img.shields.io/badge/license-MIT-black.svg" alt="MIT-Lizenz"></a>
  <img src="https://img.shields.io/badge/macOS-15%2B-black.svg" alt="macOS 15+">
  <img src="https://img.shields.io/badge/Swift-SwiftUI-black.svg" alt="Swift">
</p>

Glance bringt ein Erlebnis ähnlich wie Face ID auf dem iPhone auf deinen Mac. Ein Blick genügt zum Entsperren, ohne Tippen oder Griff zur Touch ID-Taste. Alles läuft lokal auf dem Gerät mit Apples Frameworks Vision und Core ML. Deine Gesichtsdaten und dein Mac-Passwort werden niemals ins Internet übertragen. Die Oberfläche ist in die Notch des MacBook integriert und bietet flüssige Animationen im Stil der Dynamic Island.

https://github.com/user-attachments/assets/77438826-80a9-4ab2-9fc3-42407a2d0adb

---

> [!WARNING]
> ## Vor dem Herunterladen lesen
> ## Glance ist weniger sicher als Apples Face ID oder Touch ID
>
> MacBooks besitzen keine Tiefensensoren, die Face ID auf dem iPhone zuverlässig und sicher machen. Ein iPhone erstellt eine 3D-Karte deines Gesichts. Eine MacBook-Webcam erfasst lediglich ein flaches 2D-Bild. Daraus ergeben sich folgende Einschränkungen.
>
> - Glance kann ein ausgedrucktes Foto und ein Foto auf einem Smartphone-Bildschirm mit angemessener Zuverlässigkeit abwehren (dafür muss die starke Lebenderkennung aktiviert sein).
> - Glance kann ein Video von dir nicht zuverlässig abwehren.
> - macOS bietet keine API, mit der eine Drittanbieter-App eine Anmeldung autorisieren kann. Deshalb entsperrt Glance den Mac, indem es dein gespeichertes Passwort auf dem Sperrbildschirm eingibt.
>
> Glance bietet Komfort, keine zusätzliche Sicherheit. Fahre nur fort, wenn du diese Abwägung akzeptierst.

## Installation

**Voraussetzungen**

- macOS 15 Sequoia oder neuer
- Mac mit Apple Silicon oder Intel-Prozessor

<a href="https://github.com/jonnyoo/glance/releases/latest/download/Glance.dmg" target="_self"><img width="200" src="https://github.com/user-attachments/assets/cdb8af97-1ee2-4669-b7cb-dcfb56c9dd61" alt="Für Mac herunterladen" /></a>

Öffne die `.dmg`-Datei, ziehe Glance nach `/Applications` und starte die App.

## Berechtigungen

| Berechtigung | Zweck |
|---|---|
| **Kamera** | Zum Erkennen deines Gesichts. Einzelbilder werden im Arbeitsspeicher verarbeitet und niemals auf den Datenträger geschrieben. |
| **Bedienungshilfen** | Zur Eingabe deines Passworts auf dem Sperrbildschirm. |
| **Touch ID** | Schützt den Zugriff auf den Schlüssel, der deine Gesichtsdaten und dein Passwort verschlüsselt. |

## Funktionsweise

1. Starte die App und folge der Ersteinrichtung, um dein Gesicht zu registrieren. Glance führt dich durch die Aufnahme, während du deinen Kopf in neun Richtungen drehst. Jedes Einzelbild wird in einen *Merkmalsvektor* aus 512 Zahlen umgewandelt, einen mathematischen Fingerabdruck. Anschließend wird das Bild verworfen.
2. Gib dein Mac-Passwort einmal ein. Es wird verschlüsselt und durch Touch ID geschützt.
3. Wenn dein Mac gesperrt wird oder aus dem Ruhezustand aufwacht, erscheint die Animation in der Notch und die Suche nach einem Gesicht beginnt.
4. Wenn dein Gesicht erkannt wird und die Lebenderkennung eine echte Person bestätigt, gibt Glance das Passwort ein und entsperrt den Mac.

## Funktionen

| Funktion | Beschreibung |
|---|---|
| **Gesichtsentsperrung** | Wird beim Aufwachen, beim Sperren oder durch Drücken der Leertaste auf dem Sperrbildschirm ausgelöst. Die Auslöser lassen sich beliebig kombinieren. |
| **Mehrere Identitäten** | Registriere mehrere Personen oder verschiedene Erscheinungsbilder von dir, etwa mit Brille, Bart oder bei unterschiedlichem Licht. Einzelne Identitäten lassen sich ohne Löschen deaktivieren. |
| **Lebenderkennung** | Prüft Bewegungen und Reflexionen, um ein echtes Gesicht von einem Foto zu unterscheiden. Wähle eine leichte oder starke Prüfung oder schalte sie aus. |
| **Notch-Oberfläche** | Eine kompakte Kapselform erweitert sich zu einer Scan-Animation mit Erfolgs- und Fehleranzeige. Bewege den Zeiger darüber, um es erneut zu versuchen, oder deaktiviere alle Animationen, damit Glance unsichtbar bleibt. |
| **Kamera und Bildschirm** | Wähle die verwendete Kamera, auch getrennt für das integrierte Display und einen externen Monitor. |
| **Automatische Sitzungssperre** | Die Touch ID-Sitzung wird nach einer wählbaren Inaktivitätsdauer erneut gesperrt, damit ein unbeaufsichtigter Mac nicht dauerhaft autorisiert bleibt. |
| **Trackpad-Haptik** | Beim Bewegen des Zeigers über die Notch wird haptisches Feedback ausgelöst. |
| **Unterstützung für Macs ohne Notch** | Auf Macs ohne Notch erscheint eine kapselförmige Oberfläche im Stil der Dynamic Island. |
| **Kontrolle über deine Daten** | Bearbeite oder lösche registrierte Gesichter und dein gespeichertes Passwort jederzeit. Die zugehörigen verschlüsselten Dateien werden sofort entfernt. |

---

# Datenschutz und Sicherheit

Glance ist darauf ausgelegt, biometrische Daten und Zugangsdaten auf dem Gerät zu halten.

### Gesichtsdaten

Glance speichert niemals Kamerabilder. Bei der Registrierung wird jedes aufgenommene Gesicht mithilfe eines ArcFace-basierten Core ML-Modells in einen **512-dimensionalen Merkmalsvektor** umgewandelt. Das ursprüngliche Einzelbild wird anschließend verworfen.

Die Vektoren werden lokal gespeichert und mit **AES-GCM** verschlüsselt.

### Zugangsdaten

Dein Mac-Passwort wird verschlüsselt gespeichert und niemals im Klartext auf den Datenträger geschrieben. Der Verschlüsselungsschlüssel ist ein **256-Bit-AES-Schlüssel im macOS-Schlüsselbund**, geschützt durch `userPresence`. Der Zugriff erfordert Touch ID oder das Gerätepasswort.

Der Schlüssel bleibt nur während einer aktiven, autorisierten Glance-Sitzung im Arbeitsspeicher.

### Entsperrvorgang

Damit Glance dein Passwort eingibt, müssen alle folgenden Bedingungen erfüllt sein.

1. Eine gültige Glance-Sitzung ist autorisiert.
2. Der Mac befindet sich tatsächlich auf dem Sperrbildschirm.
3. Eine aktivierte Identität überschreitet den eingestellten Ähnlichkeitsschwellenwert.
4. Das erkannte Gesicht besteht die Lebenderkennung.
5. Die Berechtigung für Bedienungshilfen zur Passworteingabe ist verfügbar.

Gesichtserkennung und Lebenderkennung laufen unabhängig voneinander. Beide müssen erfolgreich sein, bevor das Passwort eingegeben wird.

### Lokale Verarbeitung

Gesichtserkennung, Gesichtsregistrierung und Lebenderkennung laufen mit Vision und Core ML vollständig auf dem Gerät. Glance sendet weder Gesichtsdaten noch Kamerabilder oder Zugangsdaten an einen Server.

### Unterscheidung zwischen Gesicht und Foto

Fünf unabhängige Hinweise werden in einem gleitenden Zeitfenster von etwa 2 Sekunden ausgewertet und erfüllen zwei Aufgaben.

- **Ablehnungshinweise** deuten auf eine Täuschung hin, etwa Bildschirmreflexionen oder ein geräteförmiges Rechteck um das Gesicht. Jeder dieser Hinweise lässt den Scan sofort scheitern und hat Vorrang vor allen anderen Ergebnissen.
- **Bestätigungshinweise** deuten auf ein echtes Gesicht hin, etwa flache oder dreidimensionale Gesichtsmerkmalsgeometrie, Nasenparallaxe bei Kopfdrehungen und Blinzeln. Ein einzelner Hinweis genügt. Ihr Fehlen allein führt niemals zu einem Fehlschlag, da eine echte Person still sitzen kann, ohne zu blinzeln.

Die leichte Prüfung verwendet nur Ablehnungshinweise. Die starke Prüfung verwendet sowohl Ablehnungs- als auch Bestätigungshinweise.

### Face Lab

Face Lab ist eine versteckte Debug-Konsole, mit der sich Gesichtserkennung und Lebenderkennung anhand tatsächlicher Messwerte testen lassen.

Öffne Einstellungen → Über und klicke fünfmal auf das App-Symbol. In der Seitenleiste erscheint ein Debug-Bereich.

---

## Aus dem Quellcode bauen

### Voraussetzungen

- macOS 15+
- Xcode 26+

### Schritte

1. Klone das Repository.

   ```bash
   git clone https://github.com/jonnyoo/glance.git
   cd glance
   ```

2. Öffne es in Xcode.

   ```bash
   open glance.xcodeproj
   ```

3. Klicke auf die Schaltfläche zum Ausführen oder drücke `Cmd + R`.

## Mitwirken

Derzeit werden keine PRs angenommen. Du kannst gerne einen Fork dieses Projekts erstellen.

Feedback zur App kannst du unter [tryglance.app/feedback](https://tryglance.app/feedback) einreichen.

## Danksagungen

- **[The Boring Notch](https://github.com/TheBoredTeam/boring.notch)** — für die Fensterphysik der Notch.
- **[InsightFace](https://github.com/deepinsight/insightface)** — für das ArcFace-Modell zur Gesichtserkennung.
- **[Alcove](https://tryalcove.com)** — für die große Designinspiration.

## Lizenz

[MIT](../LICENSE) © Jonathan Zhou
