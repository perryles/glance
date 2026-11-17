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

<a href="https://github.com/perryles/glance/releases/latest/download/Glance-1.2.1.dmg" target="_self"><img width="200" src="https://github.com/user-attachments/assets/cdb8af97-1ee2-4669-b7cb-dcfb56c9dd61" alt="Für Mac herunterladen" /></a>

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
- Python 3.9+ und Git sowie Netzwerkzugriff für den ersten Download der Abhängigkeiten

### Build-Schritte

1. Klone diesen Fork und öffne das Projekt.

   ```bash
   git clone https://github.com/perryles/glance.git
   cd glance
   open glance.xcodeproj
   ```

2. Wähle das Target und Schema `glance`. Wähle unter **Signing & Capabilities** dein eigenes Apple-Entwicklerteam und aktiviere die automatische Signierung. Verwende `glance/glance.entitlements` für die Kamera und den geschützten Schlüsselbund.

3. Wähle **My Mac** als Ziel und drücke `Cmd + R`. Der erste signierte Build lädt festgelegte Versionen der libusb/libuvc-Quellen herunter und bindet den Infrarot-Hilfsdienst automatisch ein.

Für eine getrennte Entwicklungsinstallation kannst du einen eigenen Bundle Identifier verwenden. Zugangsdaten und Gesichtsdaten sind nach Bundle Identifier getrennt. Bei einem eigenen Bundle Identifier sind automatische Updates deaktiviert.

Einrichtung und Build-Optionen für Infrarot, einschließlich `GLANCE_ENABLE_INFRARED=NO`, stehen in der Infrarot-Anleitung. [IR](../tools/infrared/README.md)

## Mitwirken

PRs für Fehlerbehebungen, Funktionen, Übersetzungen und Dokumentation sind willkommen. Richte sie an den Branch `main` von `perryles/glance` und beschreibe die Änderungen und ihre Prüfung. [Pull Request öffnen](https://github.com/perryles/glance/compare)

Melde Fehler und Funktionswünsche über GitHub Issues. [Issues](https://github.com/perryles/glance/issues)

## Danksagungen

- Danke an Jonathan Zhou und die Glance-Mitwirkenden für die ursprüngliche App. [jonnyoo/glance](https://github.com/jonnyoo/glance)
- Danke an JediBrooker für die BRIO-Infrarot-Implementierung in PR #50. [PR #50](https://github.com/jonnyoo/glance/pull/50)
- **[The Boring Notch](https://github.com/TheBoredTeam/boring.notch)** — für die Fensterphysik der Notch.
- **[InsightFace](https://github.com/deepinsight/insightface)** — für das ArcFace-Modell zur Gesichtserkennung.
- **[Alcove](https://tryalcove.com)** — für die große Designinspiration.
- Danke an Sparkle für die App-Updates. [Sparkle](https://github.com/sparkle-project/Sparkle)
- Danke an libusb und libuvc für die USB-Infrarot-Aufnahme. [libusb](https://github.com/libusb/libusb), [libuvc](https://github.com/libuvc/libuvc)

## Lizenz

Der Projektquellcode wird unter der MIT-Lizenz verteilt. Ursprüngliches Werk © 2026 Jonathan Zhou. Beiträge zu diesem Fork © 2026 perryles und Mitwirkende. [MIT](../LICENSE)

Bibliotheken Dritter und Modellgewichte haben eigene Lizenzen. InsightFace stellt seine vortrainierten Modelle unter einer Lizenz für nichtkommerzielle Forschung bereit. [InsightFace-Lizenzhinweise](https://github.com/deepinsight/insightface#license)

Signierte Infrarot-Builds enthalten die nativen Lizenzen unter `Contents/Resources/InfraredLicenses` sowie Quellcode und Materialien zum erneuten Linken unter `Contents/Resources/InfraredSources.zip`.
