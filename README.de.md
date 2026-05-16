# DashCat

Eine leichte macOS-Menüleisten-App, die Zwischenablage-Historie, Systemmonitoring, Ruhezustand-Verhinderung und Mausrad-Umkehr in einer laufenden Katze vereint.

[中文](README.md) | [English](README.en.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt-BR.md) | [Italiano](README.it.md) | [繁體中文](README.zh-TW.md) | [Русский](README.ru.md)

---

Ich hatte mehrere Menüleisten-Tools auf macOS laufen: eines für die Systemauslastung, eines für die Zwischenablage (Maccy), eines zur Ruhezustand-Verhinderung (Caffeine) und noch eine Lösung für die Richtung externer Mausräder. Mehrere Symbole, mehrere Hintergrundprozesse — das fühlte sich irgendwann verschwenderisch an. Also habe ich alles von Grund auf neu gebaut und nur das Wesentliche behalten: Systemmonitoring, Zwischenablage-Verwaltung, Ruhezustand-Verhinderung und Mausrad-Umkehr. Der Monitor ist für Apple Silicon optimiert, die Zwischenablage-Verwaltung ist schlank und effizient, Ruhezustand-Verhinderung und Mausrad-Umkehr sind direkt eingebaut. Nichts Überflüssiges.

So entstand DashCat. Eine Katze in der Menüleiste — je schneller sie rennt, desto höher die Systemauslastung; ein Linksklick öffnet die Zwischenablage-Historie mit Sofortsuche; ein Rechtsklick zeigt Ruhezustand-Verhinderung, Mausrad-Richtung, Monitor-Modus und Sprachwechsel auf einen Blick. Ein Symbol erledigt mehrere Alltagsaufgaben. Keine Abhängigkeiten, minimaler Ressourcenverbrauch, alle Daten lokal gespeichert.

---

## Funktionen

- **Zwischenablage-Verwaltung**
  - Linksklick auf das Katzen-Symbol öffnet das Zwischenablage-Panel
  - Echtzeit-Suchfilterung
  - Klick zum Kopieren, `Option + Enter` zum Kopieren als reinen Text
  - Einträge per Rechtsklick oben anheften
  - Text- und Bildunterstützung (Bildspeicherung umschaltbar, JPEG-komprimiert)
  - Anpassbare Aufbewahrung: 7 / 14 / 30 / 90 Tage, unbegrenzt oder ein eigener Wert von 1-365 Tagen
  - Alle Daten lokal gespeichert — vollständig offline, keine Datenerfassung

- **Systemmonitor**
  - Drei Monitormodi: Kombiniert, CPU, Speicher
  - Geschwindigkeit der Katzen-Animation spiegelt die Systemauslastung in Echtzeit wider — je schneller, desto höher die Auslastung
  - Im kombinierten Modus wird automatisch die höhere CPU- oder Speicherbelastung zur Steuerung der Animation verwendet
  - Zwei Werte zeigt kompakte zweizeilige C/M-Prozentwerte
  - Anzeigemodi: Prozentwert & Animation, nur Animation, nur Prozentwert oder zwei Werte

- **Ruhezustand-Verhinderung**
  - Standardfarbe: normal — System darf in den Ruhezustand
  - Blau: System-Ruhezustand verhindern (Bildschirm kann sich noch ausschalten)
  - Orange: Display-Ruhezustand verhindern
  - Direkt über das Rechtsklick-Menü umschalten — Katzenfarbe ändert sich in Echtzeit

- **Weiteres**
  - 11 Sprachen: English, 中文, 日本語, 한국어, Deutsch, Français, Español, Português, Italiano, 繁體中文, Русский
  - Richtung externer Mausräder umkehren, während das Trackpad macOS Natural Scrolling beibehält
  - TXT- oder Markdown-Datei im aktuellen Finder-Ordner erstellen, mit Zielpfad vor dem Erstellen und optionaler Ordnerauswahl
  - Start bei Anmeldung unterstützt
  - Energieeffizient: Animation begrenzt auf 12 fps, Abfrageintervall 5 Sek., automatische Pause bei System-Ruhezustand
  - Keine externen Abhängigkeiten — reines AppKit + Swift

## Systemanforderungen

- macOS 13 (Ventura) oder neuer
- Apple Silicon Mac (M-Serie Chips)

## Installation

**Option 1: DMG-Installationsprogramm**

1. Gehen Sie zur [Releases](../../releases)-Seite dieses Repositorys und laden Sie das neueste `DashCat-<version>.dmg` herunter
2. Öffnen Sie das DMG und ziehen Sie DashCat in Ihren Programme-Ordner
3. Beim ersten Start zeigt macOS möglicherweise „App ist beschädigt" oder „Entwickler kann nicht verifiziert werden" — dies ist Gatekeeper, der eine unsignierte App blockiert; die App selbst ist in Ordnung. Führen Sie folgenden Befehl im Terminal aus, um die Quarantäne-Flagge zu entfernen:
   ```bash
   xattr -cr /Applications/DashCat.app
   ```
   Danach können Sie die App normal per Doppelklick starten. Alternativ: Rechtsklick → Öffnen → im Dialog auf Öffnen klicken.

**Option 2: Aus dem Quellcode erstellen (kein Gatekeeper-Umgehung nötig)**

1. Dieses Repository klonen
2. `DashCat.xcodeproj` in Xcode öffnen
3. Unter **Signing & Capabilities** Ihr eigenes Entwicklerkonto auswählen
4. Mit `⌘R` ausführen — Xcode signiert die App automatisch

## Verwendung

- **Linksklick** auf das Katzen-Symbol: Zwischenablage-Historie-Panel öffnen
  - Im Suchfeld eingeben zum Filtern
  - Auf einen Eintrag klicken zum Kopieren
  - `Option + Enter` zum Kopieren als reinen Text
  - Einträge per Rechtsklick anheften oder lösen
- **Rechtsklick** auf das Katzen-Symbol: Einstellungsmenü öffnen
  - Monitor-Modus, Ruhezustand-Verhinderungs-Modus umschalten
  - Zwischenablage-Historie verwalten (Bilder speichern, Aufbewahrungstage, Historie löschen)
  - Datei im aktuellen Finder-Ordner erstellen, Mausrad umkehren, Sprache wechseln, Anzeigemodus wechseln, Start bei Anmeldung

## Häufig gestellte Fragen

**Wo werden die Zwischenablage-Daten gespeichert?**

`~/Library/Application Support/DashCat/` — `clipboard.db` für Texteinträge, `Images/` für Bilddateien. Beim Löschen der Historie werden beide bereinigt.

**Wie viel Speicherplatz beanspruchen Bilder?**

Bilder werden als JPEG gespeichert (einige hundert KB pro Bild). Bildspeicherung ist standardmäßig deaktiviert. Wenn aktiviert, gilt ein Gesamtlimit von 500 MB — die ältesten nicht fixierten Bilder werden automatisch gelöscht, wenn das Limit erreicht wird.

**Was bedeuten die Katzenfarben?**

Standard → normales Ruheverhalten. **Blau** → System-Ruhezustand wird verhindert. **Orange** → Display-Ruhezustand wird verhindert. Umschalten über das Rechtsklick-Menü.

**Warum benötigt das Umkehren des Mausrads Bedienungshilfen-Berechtigung?**

DashCat muss Mausrad-Ereignisse im Systemereignisstrom erkennen und deren Richtung umkehren, daher verlangt macOS die Bedienungshilfen-Berechtigung. Ohne sie funktionieren Zwischenablage, Systemmonitor und Ruhezustand-Verhinderung weiterhin; das Rechtsklick-Menü zeigt einen Hinweis und eine Verknüpfung zu den Systemeinstellungen.

**Warum fragt das Erstellen einer Finder-Datei nach der Steuerung von Finder?**

DashCat liest den aktuellen Finder-Ordner nur, wenn Sie „Neue Datei im aktuellen Finder-Ordner“ wählen. macOS kann dafür eine Automatisierungsberechtigung anzeigen; DashCat überwacht Finder nicht im Hintergrund. Der Befehl liegt im DashCat-Menü und wird nicht in das Kontextmenü einer leeren Finder-Fläche eingefügt.

**Wird Intel Mac unterstützt?**

Nein. Nur arm64-Build, speziell für Apple Silicon entwickelt.

**Wie unterscheidet sich DashCat von Maccy / CopyClip / Amphetamine?**

DashCat vereint Zwischenablage-Verwaltung (wie Maccy), Systemmonitoring und Ruhezustand-Verhinderung (wie Amphetamine / Caffeine) in einer einzigen, leichten Menüleisten-App — ein Symbol, ein Prozess, keine Abhängigkeiten. Reines AppKit für minimalen Speicherverbrauch.

**Warum zeigt macOS beim ersten Start an, die App sei „beschädigt"?**

Die vorgebaute Version ist nicht mit einem Apple-Entwicklerzertifikat signiert, daher zeigt Gatekeeper diese Meldung — die App selbst ist in Ordnung. Führen Sie `xattr -cr /Applications/DashCat.app` im Terminal aus, um die Quarantäne-Flagge zu entfernen, und starten Sie dann normal. Um diesen Schritt zu vermeiden, bauen Sie aus dem Quellcode und signieren Sie mit Ihrem eigenen Konto.

## Lizenz

MIT License
