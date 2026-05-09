# DashCat

Un'app leggera per la barra dei menu di macOS che combina cronologia degli appunti, monitoraggio del sistema e prevenzione sospensione in un gatto che corre.

[中文](README.md) | [English](README.en.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt-BR.md) | [Italiano](README.it.md) | [繁體中文](README.zh-TW.md) | [Русский](README.ru.md)

---

Avevo tre strumenti che giravano nella barra dei menu di macOS: uno per il carico del sistema, uno per la cronologia degli appunti (Maccy), uno per prevenire la sospensione (Caffeine). Tre icone, tre processi in background — mi sembrava uno spreco. Così ne ho creato uno da zero, mantenendo solo l'essenziale: monitoraggio del sistema, gestione degli appunti e prevenzione sospensione. Il monitor è ottimizzato per Apple Silicon, il gestore degli appunti è snello ed efficiente, e la prevenzione sospensione è integrata. Proprio ciò che serve, niente di più.

Ecco com'è nato DashCat. Un gatto nella barra dei menu — più veloce corre, più alto è il carico; clic sinistro per la cronologia degli appunti con ricerca istantanea; clic destro per prevenzione sospensione, modalità monitor e cambio lingua. Un'icona fa il lavoro di tre. Zero dipendenze, uso minimo di risorse, tutti i dati salvati localmente.

---

## Funzionalità

- **Gestore Appunti**
  - Clic sinistro sull'icona del gatto per aprire il pannello cronologia appunti
  - Filtraggio ricerca in tempo reale
  - Clic per copiare, `Option + Enter` per copiare come testo semplice
  - Fissa gli elementi usati frequentemente in cima
  - Supporto testo e immagini (immagini compresse in JPEG, salvataggio immagini opzionale)
  - Retenzione personalizzabile: 7 / 14 / 30 / 90 giorni, per sempre, o un valore personalizzato di 1-365 giorni
  - Tutti i dati salvati localmente — completamente offline, nessuna raccolta dati

- **Monitor Sistema**
  - Tre modalità: Combinato, CPU, Memoria
  - La velocità dell'animazione del gatto riflette il carico del sistema in tempo reale — più veloce corre, più alta è la pressione
  - La modalità combinata sceglie automaticamente il valore più alto tra CPU e memoria per l'animazione
  - Visualizzazione opzionale della percentuale nella barra di stato

- **Prevenzione Sospensione**
  - Colore predefinito: normale — il sistema può sospendersi
  - Blu: impedire sospensione per inattività del sistema (lo schermo può ancora spegnersi)
  - Arancione: impedire che lo schermo si spenga
  - Cambia direttamente dal menu contestuale — il colore del gatto cambia in tempo reale

- **Altro**
  - 11 lingue: English, 中文, 日本語, 한국어, Deutsch, Français, Español, Português, Italiano, 繁體中文, Русский
  - Inverti la rotella di un mouse esterno mantenendo lo scorrimento naturale macOS del trackpad
  - Supporto per avvio al login
  - Efficiente: limite animazione di 12 fps, intervallo campionamento di 5 s, pausa automatica in sospensione sistema
  - Zero dipendenze esterne — AppKit + Swift puro

## Requisiti

- macOS 13 (Ventura) o successivo
- Mac con Apple Silicon (chip serie M)

## Installazione

**Opzione 1: Installatore DMG**

1. Vai alla pagina [Releases](../../releases) e scarica l'ultimo `DashCat-<versione>.dmg`
2. Apri il DMG e trascina DashCat nella cartella Applicazioni
3. Al primo avvio, macOS potrebbe mostrare "l'app è danneggiata" o "impossibile verificare lo sviluppatore" — questo è Gatekeeper che blocca un'app non firmata; l'app è integra. Esegui il seguente comando nel Terminale per rimuovere la quarantena:
   ```bash
   xattr -cr /Applications/DashCat.app
   ```
   Poi doppio clic per avviare normalmente. In alternativa, clic destro → Apri → clic su Apri nella finestra di dialogo.

**Opzione 2: Compilare da sorgente (nessuna necessità di aggirare Gatekeeper)**

1. Clona questo repository
2. Apri `DashCat.xcodeproj` in Xcode
3. Seleziona il tuo account sviluppatore in **Signing & Capabilities**
4. Esegui con `⌘R` — Xcode firma l'app automaticamente

## Utilizzo

- **Clic sinistro** sull'icona del gatto: apri pannello cronologia appunti
  - Digita nella casella di ricerca per filtrare
  - Clic su un elemento per copiarlo
  - `Option + Enter` per copiare come testo semplice
  - Fissa gli elementi usati frequentemente
- **Clic destro** sull'icona del gatto: apri menu impostazioni
  - Cambia modalità monitor, modalità prevenzione sospensione
  - Gestisci cronologia appunti (salva immagini, giorni di conservazione, cancella cronologia)
  - Inverti rotella mouse, cambia lingua, attiva/disattiva percentuale, configura avvio al login

## Domande Frequenti

**Dove sono salvati i dati degli appunti?**

`~/Library/Application Support/DashCat/` — `clipboard.db` per i record di testo, `Images/` per i file immagine. Cancellare la cronologia pulisce entrambi.

**Quanto spazio su disco usano le immagini?**

Le immagini sono salvate come JPEG (qualche centinaio di KB ciascuna). Il salvataggio immagini è disattivato di default. Quando attivato, c'è un limite totale di 500 MB — le immagini non fissate più vecchie vengono eliminate automaticamente quando si raggiunge il limite.

**Cosa significano i colori del gatto?**

Predefinito → comportamento normale di sospensione. **Blu** → impedendo sospensione del sistema. **Arancione** → impedendo sospensione dello schermo. Cambia dal menu contestuale.

**Perché invertire la rotella del mouse richiede il permesso Accessibilità?**

DashCat deve identificare gli eventi della rotella del mouse nel flusso eventi del sistema e invertirne la direzione, quindi macOS richiede il permesso Accessibilità. Senza questo permesso, cronologia appunti, monitor sistema e prevenzione sospensione continuano a funzionare; il menu contestuale mostra un avviso e un collegamento alle Impostazioni di Sistema.

**Supporta Mac Intel?**

No. Solo arm64, progettato per Apple Silicon.

**In cosa differisce da Maccy / CopyClip / Amphetamine?**

DashCat combina gestione appunti (come Maccy), monitoraggio del sistema e prevenzione sospensione (come Amphetamine / Caffeine) in un'unica app leggera della barra dei menu — un'icona, un processo, zero dipendenze. AppKit puro per uso minimo di memoria.

**Perché macOS dice che l'app è "danneggiata" o "impossibile verificare lo sviluppatore" al primo avvio?**

Il binario precompilato non è firmato con un certificato sviluppatore Apple, quindi Gatekeeper mostra questo messaggio — l'app è integra. Esegui `xattr -cr /Applications/DashCat.app` nel Terminale per rimuovere la quarantena, poi avvia normalmente. Per evitare completamente questo passaggio, compila da sorgente e firma con il tuo account.

## Licenza

MIT License
