# DashCat

Une app légère pour la barre de menus macOS qui réunit l'historique du presse-papiers, la surveillance système, la prévention de veille et l'inversion de molette dans un chat qui court.

[中文](README.md) | [English](README.en.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt-BR.md) | [Italiano](README.it.md) | [繁體中文](README.zh-TW.md) | [Русский](README.ru.md)

---

J'avais plusieurs outils dans la barre de menus macOS : un pour la charge système, un pour le presse-papiers (Maccy), un pour empêcher la mise en veille (Caffeine), et encore un réglage pour la direction de la molette d'une souris externe. Plusieurs icônes, plusieurs processus en arrière-plan — ça semblait du gaspillage. Alors j'ai tout recréé de zéro, en gardant l'essentiel : surveillance système, gestion du presse-papiers, prévention de veille et inversion de molette. Le moniteur est optimisé pour Apple Silicon, le presse-papiers est épuré et efficace, la prévention de veille et l'inversion de molette sont intégrées. Juste ce qu'il faut, rien de plus.

C'est ainsi qu'est né DashCat. Un chat dans la barre de menus — plus il court vite, plus la charge système est élevée ; un clic gauche ouvre l'historique du presse-papiers avec recherche instantanée ; un clic droit affiche la prévention de veille, la direction de la molette, le mode de surveillance et le changement de langue en un clin d'œil. Une seule icône remplace plusieurs outils du quotidien. Zéro dépendance, ressource minimale, toutes les données stockées localement.

---

## Fonctionnalités

- **Gestionnaire de presse-papiers**
  - Clic gauche sur l'icône du chat pour ouvrir le panneau d'historique du presse-papiers
  - Filtrage en temps réel dans la barre de recherche
  - Cliquer pour copier, `Option + Entrée` pour copier en texte brut
  - Clic droit sur un élément pour l'épingler en haut
  - Support texte et image (stockage d'images activable, compression JPEG)
  - Durée de conservation personnalisable : 7 / 14 / 30 / 90 jours, illimité, ou valeur personnalisée de 1 à 365 jours
  - Toutes les données stockées localement — entièrement hors ligne, aucune collecte de données

- **Moniteur système**
  - Par défaut, Valeurs compactes affiche CPU + mémoire en deux lignes C/M pour économiser la barre de menus
  - Affichage personnalisé permet de choisir la source (Combiné, CPU, Mémoire) et le style (Animation, Animation + valeur)
  - La vitesse d'animation du chat reflète la charge système en temps réel — plus il court vite, plus la charge est élevée
  - En mode combiné, la ressource la plus sollicitée (CPU ou mémoire) pilote l'animation

- **Batterie compacte**
  - Indicateur de batterie optionnel et indépendant dans la barre de menus, séparé du chat
  - Affiche un nombre étroit sans signe %, avec un remplissage bleu discret pour les barres de menus chargées
  - Peut se masquer automatiquement sur secteur, sans laisser d’espace dans la barre de menus
  - Utilise les informations d’alimentation du système avec une actualisation basse fréquence, sans animation ni surcharge

- **Prévention de la mise en veille**
  - Couleur par défaut : normale — le système peut se mettre en veille
  - Bleu : empêcher la mise en veille du système (l'écran peut encore s'éteindre)
  - Orange : empêcher la mise en veille de l'écran
  - Basculer directement depuis le menu du clic droit — la couleur du chat change en temps réel

- **Autres**
  - 11 langues : English, 中文, 日本語, 한국어, Deutsch, Français, Español, Português, Italiano, 繁體中文, Русский
  - Inverser la molette d'une souris externe tout en gardant le défilement naturel macOS du trackpad
  - Créer un fichier TXT ou Markdown dans Finder, avec affichage du chemin cible et choix possible d'un autre dossier
  - Lancement à la connexion
  - Économe en énergie : animation limitée à 12 fps, intervalle d'échantillonnage de 5 s, pause automatique lors de la mise en veille du système
  - Zéro dépendance externe — AppKit pur + Swift

## Configuration requise

- macOS 13 (Ventura) ou version ultérieure
- Mac Apple Silicon (puces M)

## Installation

**Option 1 : Installateur DMG**

1. Allez sur la page [Releases](../../releases) de ce dépôt et téléchargez le dernier `DashCat-<version>.dmg`
2. Ouvrez le DMG et glissez DashCat dans le dossier Applications
3. Au premier lancement, macOS peut afficher « l'application est endommagée » ou « impossible de vérifier le développeur » — c'est Gatekeeper qui bloque une application non signée ; l'application elle-même est intacte. Exécutez la commande suivante dans le Terminal pour supprimer le marqueur de quarantaine :
   ```bash
   xattr -cr /Applications/DashCat.app
   ```
   Ensuite, double-cliquez pour lancer normalement. Alternativement : clic droit → Ouvrir → cliquer sur Ouvrir dans la boîte de dialogue.

**Option 2 : Compiler depuis le code source (aucun contournement de Gatekeeper nécessaire)**

1. Clonez ce dépôt
2. Ouvrez `DashCat.xcodeproj` dans Xcode
3. Sélectionnez votre propre compte développeur sous **Signing & Capabilities**
4. Exécutez avec `⌘R` — Xcode signe l'application automatiquement

## Utilisation

- **Clic gauche** sur l'icône du chat : ouvrir le panneau d'historique du presse-papiers
  - Saisir dans la barre de recherche pour filtrer
  - Cliquer sur un élément pour le copier
  - `Option + Entrée` pour copier en texte brut
  - Clic droit sur un élément pour l'épingler ou le détacher
- **Clic droit** sur l'icône du chat : ouvrir le menu des paramètres
  - Basculer Monitor entre Valeurs compactes et affichage animé personnalisé
  - Gérer les images, la conservation et l'effacement dans les réglages du presse-papiers
  - Activer la batterie compacte et son masquage sur secteur
  - Créer un fichier dans Finder, inverser la molette, changer la langue, lancer au démarrage

## FAQ

**Où sont stockées les données du presse-papiers ?**

`~/Library/Application Support/DashCat/` — `clipboard.db` pour les enregistrements texte, `Images/` pour les fichiers image. Effacer l'historique nettoie les deux emplacements.

**Combien d'espace disque les images utilisent-elles ?**

Les images sont stockées en JPEG (quelques centaines de Ko chacune). L'enregistrement des images est désactivé par défaut. Lorsqu'il est activé, une limite totale de 500 Mo s'applique — les images non épinglées les plus anciennes sont automatiquement supprimées lorsque la limite est atteinte.

**Que signifient les couleurs du chat ?**

Par défaut → comportement de veille normal. **Bleu** → prévention de la mise en veille du système. **Orange** → prévention de la mise en veille de l'écran. Basculer depuis le menu du clic droit.

**Pourquoi l'inversion de la molette nécessite-t-elle l'autorisation Accessibilité ?**

DashCat doit identifier les événements de molette dans le flux d'événements système et inverser leur direction, macOS exige donc l'autorisation Accessibilité. Sans elle, l'historique du presse-papiers, le moniteur système et la prévention de veille continuent de fonctionner ; le menu du clic droit affiche une indication et un raccourci vers les Réglages Système.

**Pourquoi la création d'un fichier Finder demande-t-elle à contrôler Finder ?**

DashCat lit le dossier Finder actuel uniquement lorsque vous choisissez « Nouveau fichier dans Finder ». macOS peut afficher une demande d'autorisation d'automatisation pour obtenir ce chemin ; DashCat ne surveille pas Finder en arrière-plan. La commande se trouve dans le menu de DashCat et n'est pas injectée dans le menu contextuel d'une zone vide du Finder.

**Les Mac Intel sont-ils supportés ?**

Non. Build arm64 uniquement, conçu pour Apple Silicon.

**En quoi DashCat est-il différent de Maccy / CopyClip / Amphetamine ?**

DashCat combine la gestion du presse-papiers (comme Maccy), la surveillance système et la prévention de veille (comme Amphetamine / Caffeine) en une seule application légère dans la barre de menus — une icône, un processus, zéro dépendance. AppKit pur pour une empreinte mémoire minimale.

**Pourquoi macOS indique-t-il que l'application est « endommagée » au premier lancement ?**

La version précompilée n'est pas signée avec un certificat Apple Developer, donc Gatekeeper affiche ce message — l'application elle-même va très bien. Exécutez `xattr -cr /Applications/DashCat.app` dans le Terminal pour supprimer le marqueur de quarantaine, puis lancez normalement. Pour éviter cette étape, compilez depuis le code source et signez avec votre propre compte.

## Licence

MIT License
