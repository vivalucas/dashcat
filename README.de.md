# DashCat

[中文](README.md) | [English](README.en.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Français](README.fr.md) | [Русский](README.ru.md)

---

Ich hatte drei Menüleisten-Tools auf macOS laufen: eines für die Systemauslastung, eines für die Zwischenablage, eines zur Ruhestand-Verhinderung. Drei Symbole, drei Hintergrundprozesse — das fühlte sich irgendwann verschwenderisch an.

Kann man die nicht zusammenfassen?

So entstand DashCat. Eine Katze in der Menüleiste — je schneller sie rennt, desto höher die Systemauslastung; ein Linksklick öffnet die Zwischenablage-Historie mit Sofortsuche; ein Rechtsklick zeigt Ruhestand-Verhinderung, Monitor-Modus und Sprachwechsel auf einen Blick. Ein Symbol erledigt die Arbeit von drei. Keine Abhängigkeiten, minimaler Ressourcenverbrauch, alle Daten lokal gespeichert.

---

## Funktionen

- **Zwischenablage-Verwaltung**
  - Linksklick auf das Katzen-Symbol öffnet das Zwischenablage-Panel
  - Echtzeit-Suchfilterung
  - Klick zum Kopieren, `Option + Enter` zum Kopieren als reinen Text
  - Häufig verwendete Einträge mit Pin oben fixieren
  - Text- und Bildunterstützung (Bildspeicherung umschaltbar, JPEG-komprimiert)
  - Anpassbare Aufbewahrung: 7 / 14 / 30 / 90 Tage, unbegrenzt oder beliebiger Zeitraum
  - Alle Daten lokal gespeichert — vollständig offline, keine Datenerfassung

- **Systemmonitor**
  - Drei Modi: Kombiniert, CPU, Speicher
  - Geschwindigkeit der Katzen-Animation spiegelt die Systemauslastung in Echtzeit wider — je schneller, desto höher die Auslastung
  - Im kombinierten Modus wird automatisch die höhere CPU- oder Speicherbelastung zur Steuerung der Animation verwendet
  - Optionale Prozentanzeige in der Statusleiste

- **Ruhestand-Verhinderung**
  - Standardfarbe: normal — System darf in den Ruhezustand
  - Blau: System-Ruhezustand verhindern (Bildschirm kann sich noch ausschalten)
  - Orange: Auch Bildschirm-Ausschalten verhindern
  - Direkt über das Rechtsklick-Menü umschalten — Katzenfarbe ändert sich in Echtzeit

- **Weiteres**
  - 7 Sprachen: English, 中文, 日本語, 한국어, Deutsch, Français, Русский
  - Start bei Anmeldung unterstützt
  - Energieeffizient: Animation begrenzt auf 12 fps, Abfrageintervall 5 Sek., automatische Pause bei System-Ruhezustand
  - Keine externen Abhängigkeiten — reines AppKit + Swift

## Systemanforderungen

- macOS 26 (Tahoe) oder neuer
- Apple Silicon Mac (M-Serie Chips)

## Installation

**Option 1: DMG-Installationsprogramm**

1. Gehen Sie zur [Releases](../../releases)-Seite dieses Repositorys und laden Sie das neueste `DashCat.dmg` herunter
2. Öffnen Sie das DMG und ziehen Sie DashCat in Ihren Programme-Ordner
3. Beim ersten Start zeigt macOS möglicherweise „App ist beschädigt" oder „Entwickler kann nicht verifiziert werden" — dies ist Gatekeeper, der eine unsignierte App blockiert; die App selbst ist in Ordnung. Führen Sie folgenden Befehl im Terminal aus, um die Quarantäne-Flagge zu entfernen:
   ```bash
   xattr -cr /Applications/DashCat.app
   ```
   Danach können Sie die App normal per Doppelklick starten. Alternativ: Rechtsklick → Öffnen → im Dialog auf Öffnen klicken.

**Option 2: ZIP-Archiv**

1. Laden Sie das neueste `DashCat.zip` von der [Releases](../../releases)-Seite herunter und entpacken Sie es
2. Verschieben Sie `DashCat.app` in den Programme-Ordner
3. Im Terminal ausführen:
   ```bash
   xattr -cr /Applications/DashCat.app
   ```

**Option 3: Aus dem Quellcode erstellen (kein Gatekeeper-Umgehung nötig)**

1. Dieses Repository klonen
2. `DashCat.xcodeproj` in Xcode öffnen
3. Unter **Signing & Capabilities** Ihr eigenes Entwicklerkonto auswählen
4. Mit `⌘R` ausführen — Xcode signiert die App automatisch

## Verwendung

- **Linksklick** auf das Katzen-Symbol: Zwischenablage-Historie-Panel öffnen
  - Im Suchfeld eingeben zum Filtern
  - Auf einen Eintrag klicken zum Kopieren
  - `Option + Enter` zum Kopieren als reinen Text
  - Häufig verwendete Einträge fixieren
- **Rechtsklick** auf das Katzen-Symbol: Einstellungsmenü öffnen
  - Monitor-Modus, Ruhestand-Verhinderungs-Modus umschalten
  - Zwischenablage-Historie verwalten (Bilder speichern, Aufbewahrungstage, Historie löschen)
  - Sprache wechseln, Prozentanzeige umschalten, Start bei Anmeldung

## Häufig gestellte Fragen

**Wo werden die Zwischenablage-Daten gespeichert?**

`~/Library/Application Support/DashCat/` — `clipboard.db` für Texteinträge, `Images/` für Bilddateien. Beim Löschen der Historie werden beide Bereinigt.

**Wie viel Speicherplatz beanspruchen Bilder?**

Bilder werden als JPEG gespeichert (einige hundert KB pro Bild). Bildspeicherung ist standardmäßig deaktiviert. Wenn aktiviert, gilt ein Gesamtlimit von 500 MB — die ältesten Bilder werden automatisch gelöscht, wenn das Limit erreicht wird.

**Was bedeuten die Katzenfarben?**

Standard → normales Ruheverhalten. **Blau** → System-Ruhestand wird verhindert. **Orange** → Bildschirm-Ausschalten wird ebenfalls verhindert. Umschalten über das Rechtsklick-Menü.

**Wird Intel Mac unterstützt?**

Nein. Nur arm64-Build, speziell für Apple Silicon entwickelt.

**Wie unterscheidet sich DashCat von Maccy / CopyClip / Amphetamine?**

DashCat vereint Zwischenablage-Verwaltung (wie Maccy), Systemmonitoring und Ruhestand-Verhinderung (wie Amphetamine / Caffeine) in einer einzigen, leichten Menüleisten-App — ein Symbol, ein Prozess, keine Abhängigkeiten. Reines AppKit für minimalen Speicherverbrauch.

**Warum zeigt macOS beim ersten Start an, die App sei „beschädigt"?**

Die vorgebaute Version ist nicht mit einem Apple-Entwicklerzertifikat signiert, daher zeigt Gatekeeper diese Meldung — die App selbst ist in Ordnung. Führen Sie `xattr -cr /Applications/DashCat.app` im Terminal aus, um die Quarantäne-Flagge zu entfernen, und starten Sie dann normal. Um diesen Schritt zu vermeiden, bauen Sie aus dem Quellcode und signieren Sie mit Ihrem eigenen Konto.

## Danksagung

Basiert auf [CatMeter](https://github.com/vivalucas/CatMeter) — die Grundlage für Systemmonitor und Ruhestand-Verhinderung.

## Lizenz

MIT License
