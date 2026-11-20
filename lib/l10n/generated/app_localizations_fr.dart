// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class SFr extends S {
  SFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'DevConnect Outil de Gestion';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Annuler';

  @override
  String get close => 'Fermer';

  @override
  String get clear => 'Effacer';

  @override
  String get copy => 'Copier';

  @override
  String get copied => 'Copié';

  @override
  String get start => 'Démarrer';

  @override
  String get stop => 'Arrêter';

  @override
  String get on => 'Activé';

  @override
  String get off => 'Désactivé';

  @override
  String get autoScroll => 'Défilement auto';

  @override
  String get newestFirst => 'Plus récent d\'abord';

  @override
  String get oldestFirst => 'Plus ancien d\'abord';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get clearAllCache => 'Vider tout le cache';

  @override
  String get clearAllCacheDesc =>
      'Déconnecter tous les appareils et effacer toutes les données en mémoire (logs, captures réseau, état, performances, etc.). Vos paramètres (thème, langue, port) sont conservés.';

  @override
  String get clearAllCacheConfirm =>
      'Vider tout le cache ?\n\nCela déconnectera tous les appareils connectés et effacera tous les logs, captures réseau, changements d\'état, métriques de performance et benchmarks en mémoire.\n\nVos paramètres (thème, langue, port) seront conservés.';

  @override
  String get cacheCleared => 'Cache vidé. Paramètres conservés.';

  @override
  String clearAllCacheFailed(Object error) {
    return 'Échec du vidage du cache : $error';
  }

  @override
  String get deviceHistory => 'Appareils en cache';

  @override
  String get deviceHistoryDesc =>
      'Tous les appareils qui se sont connectés à ce bureau. Les entrées persistent entre les redémarrages pour que vous puissiez voir ce qui était présent.';

  @override
  String get noDeviceHistory => 'Aucun appareil ne s\'est encore connecté';

  @override
  String get deviceHistoryEmptyHint =>
      'Connectez un appareil via le SDK et il apparaîtra ici. Les entrées persistent entre les redémarrages.';

  @override
  String get restarting => 'Redémarrage…';

  @override
  String get online => 'en ligne';

  @override
  String get offline => 'hors ligne';

  @override
  String get markOnline => 'Marquer en ligne';

  @override
  String get markOffline => 'Marquer hors ligne';

  @override
  String get deviceOnline => 'En ligne';

  @override
  String get deviceOffline => 'Hors ligne';

  @override
  String lastSeen(Object time) {
    return 'Vu pour la dernière fois $time';
  }

  @override
  String firstSeen(Object time) {
    return 'Vu pour la première fois $time';
  }

  @override
  String get forgetDevice => 'Oublier';

  @override
  String get forgetAllOffline => 'Oublier tous les hors ligne';

  @override
  String get forgetAllDevices => 'Tout oublier';

  @override
  String get forgetDeviceConfirm =>
      'Oublier cet appareil ?\n\nIl sera supprimé de l\'historique. À la prochaine connexion, il apparaîtra comme une nouvelle entrée.';

  @override
  String get forgetAllOfflineConfirm =>
      'Oublier tous les appareils hors ligne ?\n\nCela supprime toutes les entrées non connectées. Les appareils en ligne sont conservés.';

  @override
  String get forgetAllDevicesConfirm =>
      'Oublier tous les appareils en cache ?\n\nCela efface tout l\'historique, y compris les appareils en ligne. Ils réapparaîtront à la reconnexion.';

  @override
  String get deviceForgotten => 'Appareil oublié';

  @override
  String devicesForgotten(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appareils oubliés',
      one: '1 appareil oublié',
      zero: 'Aucun appareil oublié',
    );
    return '$_temp0';
  }

  @override
  String connectionCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count connexions',
      one: '1 connexion',
      zero: 'jamais connecté',
    );
    return '$_temp0';
  }

  @override
  String get restartServer => 'Redémarrer le serveur';

  @override
  String portOccupied(Object port) {
    return 'Port $port occupé';
  }

  @override
  String get serverRestarted => 'Serveur redémarré';

  @override
  String get restartFailed => 'Échec du redémarrage';

  @override
  String portStillInUse(Object port) {
    return 'Le port $port est toujours utilisé';
  }

  @override
  String couldNotRestart(Object port) {
    return 'Impossible de redémarrer sur le port $port';
  }

  @override
  String listeningOnPort(Object port) {
    return 'Écoute sur le port $port';
  }

  @override
  String waitingForReconnect(Object port) {
    return 'Port $port · en attente de reconnexion';
  }

  @override
  String reconnectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appareils reconnectés',
      one: '1 appareil reconnecté',
      zero: '0 reconnecté',
    );
    return '$_temp0';
  }

  @override
  String get reloadApp => 'Recharger l\'application';

  @override
  String get reloadAppHotReload => 'Rechargement à chaud';

  @override
  String get reloadAppHotRestart => 'Redémarrage à chaud';

  @override
  String get reloadAppMetro => 'Recharger Metro';

  @override
  String get reloadAppNoDevices => 'Aucun appareil connecté';

  @override
  String get reloadSent => 'Rechargement envoyé';

  @override
  String sentReloadTo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rechargement envoyé à $count appareils',
      one: 'Rechargement envoyé à 1 appareil',
      zero: 'Aucun appareil ciblé',
    );
    return '$_temp0';
  }

  @override
  String get screenshotSaved => 'Capture d\'écran enregistrée';

  @override
  String get screenshotFailed => 'Échec de la capture';

  @override
  String get reveal => 'Ouvrir';

  @override
  String get captureFull => 'Complet';

  @override
  String get captureTab => 'Onglet';

  @override
  String get captureFullTooltip => 'Capturer tous les détails en image';

  @override
  String get captureTabTooltip => 'Capturer uniquement l\'onglet actuel';

  @override
  String get captureAsImage => 'Capturer en image';

  @override
  String get captureDetailAsImage => 'Capturer les détails en image';

  @override
  String get noData => 'Aucune donnée';

  @override
  String get noItems => 'Aucun élément';

  @override
  String get searchHint => 'Rechercher...';

  @override
  String get filterHint => 'Filtrer...';

  @override
  String get value => 'Valeur';

  @override
  String get key => 'Clé';

  @override
  String get metadata => 'Métadonnées';

  @override
  String get duration => 'Durée';

  @override
  String get error => 'Erreur';

  @override
  String get json => 'JSON';

  @override
  String get tree => 'Tree';

  @override
  String get code => 'Code';

  @override
  String get raw => 'Brut';

  @override
  String get format => 'Format';

  @override
  String get pretty => 'Formaté';

  @override
  String get collapse => 'Réduire';

  @override
  String get showMore => 'Voir plus';

  @override
  String get noHeaders => 'Aucun en-tête';

  @override
  String get inProgress => 'en cours';

  @override
  String get inProgressDots => 'En cours...';

  @override
  String hideShowTooltip(Object action, Object label) {
    return '$action $label';
  }

  @override
  String get hide => 'Masquer';

  @override
  String get show => 'Afficher';

  @override
  String get steps => 'étapes';

  @override
  String get portInUse =>
      'Le port est déjà utilisé. Fermez l\'autre application utilisant ce port, ou choisissez un autre port dans les Paramètres.';

  @override
  String portInUseShort(Object port) {
    return 'Le port $port est déjà utilisé. Fermez l\'autre application utilisant ce port, ou entrez un autre port ci-dessus et appuyez sur Démarrer.';
  }

  @override
  String failedToStartServer(Object msg) {
    return 'Impossible de démarrer le serveur : $msg';
  }

  @override
  String failedToStartServerOnPort(Object msg, Object port) {
    return 'Impossible de démarrer le serveur sur le port $port : $msg';
  }

  @override
  String get settings => 'Paramètres';

  @override
  String get server => 'Serveur';

  @override
  String get serverRunning => 'Serveur en cours';

  @override
  String get serverStopped => 'Serveur arrêté';

  @override
  String get port => 'Port';

  @override
  String deviceCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appareils',
      one: '1 appareil',
      zero: '0 appareil',
    );
    return '$_temp0';
  }

  @override
  String get network => 'Réseau';

  @override
  String get hostname => 'Nom d\'hôte';

  @override
  String get noNetworkInterfaces => 'Aucune interface réseau trouvée';

  @override
  String copiedIp(Object ip) {
    return '$ip copié';
  }

  @override
  String connectedDevices(Object count) {
    return 'Appareils connectés ($count)';
  }

  @override
  String get noDevicesConnected => 'Aucun appareil connecté';

  @override
  String get appearance => 'Apparence';

  @override
  String get theme => 'Thème';

  @override
  String get dark => 'Sombre';

  @override
  String get light => 'Clair';

  @override
  String get bottom => 'Bas';

  @override
  String get top => 'Haut';

  @override
  String get language => 'Langue';

  @override
  String get tabVisibility => 'Visibilité des onglets';

  @override
  String get tabVisibilityDesc =>
      'Basculer la visibilité des onglets. Les onglets désactivés affichent une icône de verrouillage et leurs données sont exclues de Tous les événements.';

  @override
  String get detailView => 'Vue détaillée';

  @override
  String get detailViewDesc =>
      'Mémorise l\'affichage des corps de requête/réponse et contrôle l\'animation de changement d\'onglet.';

  @override
  String get dataRetention => 'Rétention des données';

  @override
  String get dataRetentionDesc =>
      'Limite stricte appliquée à chaque liste par fonctionnalité. Lorsqu\'une liste dépasse la limite, les entrées les plus anciennes sont supprimées en FIFO. Les opérations asynchrones en attente sont préservées.';

  @override
  String get maxItems => 'Éléments max';

  @override
  String get dataRetentionHelper =>
      'Illimité conserve toutes les entrées. Des valeurs plus faibles libèrent de la mémoire mais perdent l\'historique.';

  @override
  String get allEventsDisplay => 'Affichage Tous les événements';

  @override
  String get allEventsDisplayDesc =>
      'Filtre en lecture seule pour la liste agrégée Tous les événements. Les logs sous-jacents ne sont pas supprimés — repassez sur Illimité pour tout restaurer.';

  @override
  String get allEventsDisplayHelper =>
      'Des valeurs plus faibles conservent les N entrées les plus récentes au prix de l\'historique plus ancien.';

  @override
  String get bodyView => 'Affichage du corps';

  @override
  String get tabAnimation => 'Animation d\'onglet';

  @override
  String get tabAnimationDuration => 'Durée';

  @override
  String get codeModeDesc =>
      'Le mode code exporte en TypeScript / Dart / Kotlin selon le SDK connecté.';

  @override
  String get treeModeDesc =>
      'Le mode arborescence affiche les données sous forme de hiérarchie de nœuds dépliables. Idéal pour parcourir des valeurs profondément imbriquées.';

  @override
  String get jsonModeDesc =>
      'Le mode JSON affiche les données sous forme de document JSON unique, coloré syntaxiquement et facile à copier.';

  @override
  String get captureDataJson =>
      'Capturer les données (clé + valeur dans le mode actuel)';

  @override
  String get captureDataText =>
      'Capturer les données (clé + valeur sous forme de texte)';

  @override
  String get copyKey => 'Copier la clé';

  @override
  String get usbConnection => 'Connexion USB';

  @override
  String get android => 'Android';

  @override
  String get ios => 'iOS';

  @override
  String get runAdbReverse => 'Exécuter ADB Reverse';

  @override
  String adbNotFound(Object home) {
    return 'adb introuvable.\nHOME=$home';
  }

  @override
  String adbReverseOk(Object path) {
    return 'adb reverse OK ($path)';
  }

  @override
  String adbError(Object error) {
    return 'Erreur adb : $error';
  }

  @override
  String adbException(Object error) {
    return 'Exception adb : $error';
  }

  @override
  String get devices => 'Appareils';

  @override
  String get adbDevices => 'Appareils ADB';

  @override
  String get wifiAutoConnect =>
      'Un iPhone se connecte par Wi‑Fi : mettez-le sur le même réseau que ce Mac. Un câble USB seul ne peut pas le connecter.';

  @override
  String get quickStart => 'Démarrage rapide';

  @override
  String get installSdk => 'Installer le SDK';

  @override
  String get initialize => 'Initialiser';

  @override
  String get connect => 'Connecter';

  @override
  String get supportDevConnect => 'Soutenir DevConnect';

  @override
  String get supportDevConnectDesc =>
      'DevConnect Outil de Gestion est gratuit et open source. S\'il aide votre flux de travail, envisagez de soutenir le développement.';

  @override
  String get kofi => 'Ko-fi';

  @override
  String get paypal => 'PayPal';

  @override
  String get ethernet => 'Ethernet';

  @override
  String get wifi => 'WiFi';

  @override
  String get vpn => 'VPN';

  @override
  String get bridge => 'Pont';

  @override
  String get loopback => 'Boucle locale';

  @override
  String get console => 'Console';

  @override
  String get state => 'État';

  @override
  String get storage => 'Stockage';

  @override
  String get database => 'Base de données';

  @override
  String get performance => 'Performance';

  @override
  String get memoryLeaks => 'Fuites mémoire';

  @override
  String get history => 'Historique';

  @override
  String get noNetworkRequests => 'Aucune requête réseau';

  @override
  String get apiCallsAppearHere =>
      'Les appels API apparaîtront ici en temps réel';

  @override
  String clearStaleButton(Object count) {
    return 'Obsolète ($count)';
  }

  @override
  String clearStaleTooltip(Object count) {
    return 'Supprimer $count requêtes en attente sans réponse depuis plus de 10 minutes';
  }

  @override
  String clearStaleSnackbar(Object count) {
    return '$count requête(s) obsolète(s) supprimée(s) (en attente > 10 min)';
  }

  @override
  String memorySafetyOverflow(Object count) {
    return 'Sécurité mémoire: $count entrée(s) réseau obsolète(s) supprimée(s) du cache open-trips';
  }

  @override
  String get sdkTipsPill => 'Tips lib';

  @override
  String get sdkTipsHeader => 'Compatibilité des bibliothèques';

  @override
  String get sdkTipsSubtitle =>
      'Pour que toutes les données s\'affichent correctement, assurez-vous que les bibliothèques sont à la dernière version.';

  @override
  String get sdkTipsFlutter => 'Flutter';

  @override
  String get sdkTipsReactNative => 'React Native';

  @override
  String get sdkTipsAndroid => 'Android';

  @override
  String sdkTipsVersionLabel(Object version) {
    return 'v$version';
  }

  @override
  String sdkTipsPillLatest(Object version) {
    return 'v$version · Dernière version';
  }

  @override
  String sdkTipsPillUpdate(Object version) {
    return 'v$version · Mettre à jour';
  }

  @override
  String get sdkTipsInstalled => 'Installé';

  @override
  String get sdkTipsLatestLabel => 'Récent';

  @override
  String get sdkTipsUpdate => 'Mettre à jour';

  @override
  String get sdkTipsChecking => 'Vérification';

  @override
  String get sdkTipsOffline => 'Vérification indisponible';

  @override
  String get sdkTipsRetry => 'Réessayer';

  @override
  String get sdkTipsCheckProject =>
      'Exécutez ceci dans votre projet pour voir la version installée :';

  @override
  String get sdkTipsInstallLatest => 'Installer la dernière version :';

  @override
  String get appUpdateTitle => 'Version de DevConnect';

  @override
  String get appUpdateAvailable => 'Une nouvelle version est disponible.';

  @override
  String get appUpdateUpToDate => 'Vous utilisez la dernière version.';

  @override
  String get appUpdateViewRelease => 'Voir la version';

  @override
  String devicesConnected(Object count) {
    return '$count connecté(s)';
  }

  @override
  String get devicesAll => 'Tous';

  @override
  String devicesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appareils',
      one: '1 appareil',
    );
    return '$_temp0';
  }

  @override
  String get commandsTitle => 'Commandes personnalisées';

  @override
  String get commandsNoDevice =>
      'Connectez un appareil pour lancer ses commandes.';

  @override
  String get commandsEmptyHint =>
      'Aucune commande enregistrée. Ajoutez-en une dans l\'app avec DevConnect.registerCommand(name, handler), ou saisissez un nom de commande pour la lancer.';

  @override
  String get commandsName => 'Commande';

  @override
  String get commandsArgs => 'Arguments — objet JSON, facultatif';

  @override
  String get commandsArgsInvalid => 'Les arguments doivent être un objet JSON.';

  @override
  String get commandsRun => 'Exécuter';

  @override
  String commandsTarget(Object device) {
    return 'S\'exécute sur $device';
  }

  @override
  String get commandsHistoryEmpty =>
      'Les résultats des commandes exécutées s\'affichent ici.';

  @override
  String get commandsNoResponse =>
      'Pas de réponse. La commande est-elle enregistrée dans l\'app ?';

  @override
  String get dbTables => 'Tables';

  @override
  String get dbRefresh => 'Recharger les tables';

  @override
  String get dbNoDevice =>
      'Connectez un appareil pour parcourir ses bases de données.';

  @override
  String get dbSelectDevice =>
      'Sélectionnez un appareil dans la barre du bas pour parcourir ses bases de données.';

  @override
  String get dbNoDatabases =>
      'Aucune base de données enregistrée. Ajoutez-en une dans l\'app avec DevConnect.registerDatabase(name, query), puis rechargez les tables.';

  @override
  String get dbRun => 'Exécuter';

  @override
  String get dbRunHint => 'Choisissez une table ou écrivez du SQL';

  @override
  String get dbRunHintSubtitle =>
      'Choisir une table affiche ses 50 premières lignes.';

  @override
  String dbRows(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lignes',
      one: '1 ligne',
    );
    return '$_temp0';
  }

  @override
  String dbTruncated(Object count) {
    return 'seulement les $count premières';
  }

  @override
  String get dbNoResponse =>
      'Pas de réponse. L\'app enregistre-t-elle une base avec DevConnect.registerDatabase ? Il faut le dernier SDK.';

  @override
  String get stateToolsTab => 'Contrôles';

  @override
  String get stateNoDevice =>
      'Sélectionnez un appareil dans la barre du bas pour suivre, capturer et piloter son état.';

  @override
  String get stateNoState => 'Cet appareil n\'a encore envoyé aucun état.';

  @override
  String get stateSubscriptions => 'Abonnements';

  @override
  String get stateSubscriptionsHint =>
      'Épinglez un chemin pour suivre sa valeur en direct, par ex. auth.user.name ou cart.items[0].price. Fonctionne sur toutes les plateformes sans code dans l\'app ; lit l\'état du dernier changement : tout le store avec Redux, le store ou provider modifié en dernier avec Zustand, MobX, Riverpod ou un ViewModel.';

  @override
  String get statePinPath => 'Épingler le chemin';

  @override
  String get statePathMissing => '(absent de l\'état)';

  @override
  String get stateRemove => 'Supprimer';

  @override
  String get stateSnapshots => 'Instantanés';

  @override
  String get stateSnapshotsHint =>
      'Enregistrez le dernier état, puis renvoyez-le pour reproduire un bug ou sauter un long formulaire. L\'enregistrement fonctionne partout ; Restore nécessite que l\'app applique l\'état avec onStateRestore sur React Native, Flutter et Android.';

  @override
  String get stateTakeSnapshot => 'Prendre un instantané';

  @override
  String stateKeys(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clés',
      one: '1 clé',
    );
    return '$_temp0';
  }

  @override
  String get stateRestore => 'Restaurer';

  @override
  String get stateRestoreHere => 'Restaurer l\'état de l\'app à ce point';

  @override
  String get stateSaveSnapshot => 'Enregistrer comme instantané';

  @override
  String get stateSnapshotSaved => 'Instantané enregistré';

  @override
  String get stateRestoreSent => 'Restauration de l\'état envoyée';

  @override
  String get stateDispatch => 'Dispatcher une action';

  @override
  String get stateDispatchHint =>
      'Envoyez une action, un objet JSON avec un \"type\" comme \"LOGOUT\", à l\'app. React Native l\'exécute dans le store Redux branché avec connectReduxStore(store) ; Flutter et Android la transmettent à onReduxDispatch.';

  @override
  String get stateDispatchButton => 'Dispatcher';

  @override
  String get stateDispatchSent => 'Action envoyée';

  @override
  String stateSetupIn(String platform) {
    return 'Configurer dans votre app $platform';
  }

  @override
  String get stateActionInvalid => 'L\'action doit être un objet JSON.';

  @override
  String get stateRecentActions => 'Récentes';

  @override
  String get jsonTreeView => 'Arbre';

  @override
  String get jsonTableView => 'Tableau';

  @override
  String get jsonSearchHint => 'Rechercher clés et valeurs';

  @override
  String get jsonExportCsv => 'Télécharger le tableau (CSV)';

  @override
  String get jsonTableNoMatch => 'Aucune ligne ne correspond';

  @override
  String get jsonPrevMatch => 'Résultat précédent';

  @override
  String get jsonNextMatch => 'Résultat suivant';

  @override
  String get jsonExpandAll => 'Tout déplier';

  @override
  String get jsonCollapseAll => 'Tout replier';

  @override
  String get jsonCopyKey => 'Copier la clé';

  @override
  String get jsonCopyValue => 'Copier la valeur';

  @override
  String get jsonCopyPath => 'Copier le chemin';

  @override
  String get jsonKeyCopied => 'Clé copiée';

  @override
  String get jsonValueCopied => 'Valeur copiée';

  @override
  String get jsonPathCopied => 'Chemin copié';

  @override
  String jsonShowMore(int count, int remaining) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat remainingNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String remainingString = remainingNumberFormat.format(remaining);

    return 'Afficher $countString de plus ($remainingString restants)';
  }

  @override
  String jsonLongValue(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString caractères, copiez pour tout avoir';
  }

  @override
  String jsonPrettyCut(int shown, int total) {
    final intl.NumberFormat shownNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String shownString = shownNumberFormat.format(shown);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Affichage des $shownString premières lignes sur $totalString. Copiez ou enregistrez pour tout avoir.';
  }

  @override
  String jsonTableTruncated(Object count) {
    return 'Seules les $count premières lignes sont affichées.';
  }

  @override
  String get networkErrors => 'Erreurs';

  @override
  String get networkSearchBodies =>
      'Chercher aussi dans les corps de requête et de réponse';

  @override
  String get networkExportHar => 'Exporter les requêtes affichées en HAR';

  @override
  String get networkNothingToExport => 'Aucune requête à exporter';

  @override
  String get fileSaved => 'Fichier enregistré';

  @override
  String get consoleGroupRepeats => 'Regrouper les logs répétés';

  @override
  String get consoleOccurrences => 'Occurrences';

  @override
  String get consoleNoMatchTitle => 'Aucun log ne correspond';

  @override
  String get consoleNoMatchSubtitle => 'Retirez un filtre pour les retrouver.';

  @override
  String get consoleShowAllLevels => 'Afficher tous les niveaux';

  @override
  String get consoleClearSearch => 'Effacer la recherche';

  @override
  String get consoleResetFilters => 'Réinitialiser les filtres';

  @override
  String get consoleExport => 'Exporter les logs';

  @override
  String get consoleExportText => 'Texte (.txt)';

  @override
  String get consoleExportJson => 'JSON (.json)';

  @override
  String get consoleNothingToExport => 'Aucun log à exporter';

  @override
  String get errorSymbolicate => 'Symboliser';

  @override
  String get errorSymbolicated => 'Rapporté au code source';

  @override
  String get errorSymbolicateFailed =>
      'Impossible de résoudre cette pile : Metro est injoignable et aucune source map n\'a été envoyée pour ce build (uploadSourceMap dans le SDK).';

  @override
  String get storageTabHistory => 'Historique';

  @override
  String get storageTabKeyValue => 'Clé-valeur';

  @override
  String get storageKvNoDevice =>
      'Sélectionnez un appareil dans la barre du bas pour voir et modifier son stockage.';

  @override
  String get storageKvEmpty =>
      'Aucun stockage modifiable. Enveloppez le store avec le SDK (DevConnectAsyncStorage.wrap, DevConnectMMKV.wrap, DevConnectSharedPreferences.wrap…) — il faut le dernier SDK.';

  @override
  String get storageKvRefresh => 'Recharger';

  @override
  String get storageKvAdd => 'Ajouter une clé';

  @override
  String get storageKvEdit => 'Modifier la valeur';

  @override
  String get storageKvDelete => 'Supprimer la clé';

  @override
  String get storageKvClear => 'Tout effacer';

  @override
  String storageKvClearConfirm(Object storage) {
    return 'Supprimer toutes les clés de $storage ? Action irréversible.';
  }

  @override
  String get storageKvKey => 'Clé';

  @override
  String get storageKvValue => 'Valeur';

  @override
  String get storageKvSave => 'Enregistrer';

  @override
  String get storageKvFilter => 'Filtrer les clés';

  @override
  String get storageNoMatchTitle => 'Aucune opération ne correspond';

  @override
  String get storageNoMatchSubtitle => 'Retirez un filtre pour les retrouver.';

  @override
  String get storageShowAllOps => 'Afficher toutes les opérations';

  @override
  String get storageShowAllTypes => 'Afficher tous les types de stockage';

  @override
  String get storageCopyValue => 'Copier la valeur';

  @override
  String get storageKvNoMatch => 'Aucune clé ne correspond';

  @override
  String storageFilterHide(String name) {
    return 'Masquer $name';
  }

  @override
  String storageFilterShow(String name) {
    return 'Afficher $name';
  }

  @override
  String get deepLinkTitle => 'Ouvrir un lien profond';

  @override
  String get deepLinkHint =>
      'L\'app l\'ouvre comme si l\'un de ses liens avait été touché.';

  @override
  String get deepLinkOpen => 'Ouvrir';

  @override
  String get deepLinkSent => 'Lien profond envoyé';

  @override
  String get devMenu => 'Ouvrir le menu de dev';

  @override
  String get networkReplay => 'Rejouer la requête';

  @override
  String get networkReplaySent =>
      'Requête renvoyée — elle apparaît comme une nouvelle ligne';

  @override
  String get networkConditions => 'Conditions réseau';

  @override
  String get networkPresetNormal => 'Normal';

  @override
  String get networkPresetSlow => 'Lent (+500 ms)';

  @override
  String get networkPresetSlow3g => '3G lente (~2 s)';

  @override
  String get networkPresetOffline => 'Hors ligne';

  @override
  String get networkTabHttpHint =>
      'Requêtes HTTP envoyées par l\'app via fetch, XHR, axios, Dio, OkHttp…';

  @override
  String get networkTabProtocolsHint =>
      'Trafic au-delà du HTTP simple : opérations GraphQL, messages WebSocket et appels gRPC';

  @override
  String get networkTabMockAuditHint =>
      'Requêtes auxquelles l\'app a répondu avec une règle du Mock Server au lieu du vrai réseau';

  @override
  String get protocolGraphqlHint =>
      'Requêtes et mutations envoyées via le lien / l\'intercepteur GraphQL du SDK';

  @override
  String get protocolWebsocketHint =>
      'Connexions WebSocket et chaque trame envoyée ou reçue';

  @override
  String get protocolGrpcHint => 'Appels gRPC (intercepteur du SDK Android)';

  @override
  String get layoutTitle => 'Mise en page';

  @override
  String get layoutCapture => 'Capturer';

  @override
  String get layoutHint =>
      'Capturez l\'écran actuel de l\'app pour voir son arbre d\'éléments. Survolez la capture pour surligner un élément, cliquez pour voir ses propriétés.';

  @override
  String get layoutNoDevice =>
      'Connectez une app ou sélectionnez un appareil pour inspecter sa mise en page.';

  @override
  String get layoutNoScreenshot =>
      'Pas de capture d\'écran de cette app, seuls les contours des éléments sont affichés. React Native : ajoutez-en une avec DevConnect.registerScreenshot.';

  @override
  String get layoutPickElement =>
      'Survolez ou cliquez sur un élément de la capture, ou choisissez-en un dans l\'arbre.';

  @override
  String get layoutTree => 'Arbre des éléments';

  @override
  String get layoutProperties => 'Propriétés';

  @override
  String get layoutTreeError => 'Impossible de lire l\'arbre des éléments';

  @override
  String get layoutSearchHint => 'Rechercher par nom ou valeur';

  @override
  String get layoutAppOnly => 'Éléments de l\'app uniquement';

  @override
  String get layoutFit => 'Ajuster';

  @override
  String get layoutActualSize => 'Taille réelle';

  @override
  String get layoutZoomIn => 'Zoom avant';

  @override
  String get layoutZoomOut => 'Zoom arrière';

  @override
  String get layoutZoomLevel => 'Niveau de zoom';

  @override
  String get layoutZoomToSelection => 'Zoomer sur la sélection';

  @override
  String get layoutClose => 'Fermer la capture';

  @override
  String get layoutCopyName => 'Copier le nom';

  @override
  String get layoutCopyJson => 'Copier en JSON';

  @override
  String get layoutExport => 'Exporter';

  @override
  String get layoutSavePng => 'Enregistrer la capture (PNG)';

  @override
  String get layoutSaveJson => 'Enregistrer le snapshot (JSON)';

  @override
  String get layoutNoAnswer =>
      'L\'app n\'a pas répondu. La mise en page nécessite un SDK DevConnect qui la prend en charge, dans un build de debug.';

  @override
  String get layoutTruncated =>
      'Arbre volumineux : seule la première partie a été capturée.';

  @override
  String get layoutState => 'État';

  @override
  String get layoutMeasureHint => '⌥ + survol : mesurer';

  @override
  String get networkTitle => 'Réseau';

  @override
  String get filterUrls => 'Filtrer les URL...';

  @override
  String get copyUrl => 'Copier l\'URL';

  @override
  String get urlCopied => 'URL copiée';

  @override
  String get copyPath => 'Copier le chemin';

  @override
  String get pathCopied => 'Chemin copié';

  @override
  String get copyCurl => 'Copier cURL';

  @override
  String get curlCopied => 'cURL copié';

  @override
  String get copyRequest => 'Copier la requête';

  @override
  String get requestCopied => 'Requête copiée';

  @override
  String get copyResponse => 'Copier la réponse';

  @override
  String get responseCopied => 'Réponse copiée';

  @override
  String get requestBody => 'Corps de la requête';

  @override
  String get responseBody => 'Corps de la réponse';

  @override
  String get requestHeaders => 'En-têtes de requête';

  @override
  String get responseHeaders => 'En-têtes de réponse';

  @override
  String get headers => 'En-têtes';

  @override
  String get request => 'Requête';

  @override
  String get response => 'Réponse';

  @override
  String get timing => 'Chronométrage';

  @override
  String get startTime => 'Heure de début';

  @override
  String get endTime => 'Heure de fin';

  @override
  String noLabel(Object label) {
    return 'Aucun $label';
  }

  @override
  String get noStorageData => 'Aucune donnée de stockage';

  @override
  String get storageEntriesAppearHere =>
      'Les entrées SharedPreferences, AsyncStorage et Hive apparaîtront ici';

  @override
  String get storageTitle => 'Stockage';

  @override
  String get filterKeys => 'Filtrer les clés...';

  @override
  String get read => 'LECTURE';

  @override
  String get write => 'ÉCRITURE';

  @override
  String get delete => 'SUPPRESSION';

  @override
  String get noEventsYet => 'Aucun événement';

  @override
  String get startAppToSeeEvents =>
      'Démarrez votre application avec DevConnect SDK pour voir les événements';

  @override
  String get eventsAppearHere =>
      'Les événements apparaîtront ici en temps réel';

  @override
  String get allEventsTitle => 'Tous les événements';

  @override
  String get stopped => 'Arrêté';

  @override
  String get searchEvents => 'Rechercher des événements...';

  @override
  String get logDetail => 'Détail du journal';

  @override
  String get networkDetail => 'Détail réseau';

  @override
  String get stateDetail => 'Détail d\'état';

  @override
  String get storageDetail => 'Détail de stockage';

  @override
  String get displayDetail => 'Détail d\'affichage';

  @override
  String get asyncOperation => 'Opération asynchrone';

  @override
  String get errorDetail => 'Détail de l\'erreur';

  @override
  String get tag => 'Étiquette';

  @override
  String get message => 'Message';

  @override
  String get stackTrace => 'Pile d\'exécution';

  @override
  String get noLogsYet => 'Aucun journal';

  @override
  String get connectDeviceToSeeLogs =>
      'Connectez un appareil et commencez à journaliser pour voir les entrées ici';

  @override
  String get consoleTitle => 'Console';

  @override
  String get searchLogs => 'Rechercher dans les journaux...';

  @override
  String get clearConsole => 'Effacer la console';

  @override
  String get copyMessage => 'Copier le message';

  @override
  String get logCopied => 'Journal copié';

  @override
  String get closePanel => 'Fermer le panneau';

  @override
  String hideShowLogs(Object action, Object label) {
    return '$action les journaux $label';
  }

  @override
  String get errors => 'Erreurs';

  @override
  String get searchErrors => 'Rechercher des erreurs...';

  @override
  String get clearErrors => 'Effacer les erreurs';

  @override
  String get totalErrors => 'Total des erreurs';

  @override
  String get fatalCrash => 'Fatal/Plantage';

  @override
  String get noErrorsCaptured => 'Aucune erreur capturée';

  @override
  String get errorsAppearHere =>
      'Les erreurs de React Native et Flutter apparaîtront ici';

  @override
  String get stackTraceCopied => 'Pile d\'exécution copiée';

  @override
  String get noStackTrace => 'Aucune pile d\'exécution';

  @override
  String get platform => 'Plateforme';

  @override
  String get severity => 'Sévérité';

  @override
  String get source => 'Source';

  @override
  String get deviceId => 'ID appareil';

  @override
  String get deviceInfo => 'Infos appareil';

  @override
  String get details => 'Détails';

  @override
  String hideShowErrors(Object action, Object label) {
    return '$action les erreurs $label';
  }

  @override
  String get noStateChanges => 'Aucun changement d\'état';

  @override
  String get stateChangesAppearHere =>
      'Les changements d\'état Redux, BLoC, Riverpod et MobX apparaîtront ici';

  @override
  String get stateInspectorTitle => 'Inspecteur d\'état';

  @override
  String changesCount(Object count) {
    return '$count changements';
  }

  @override
  String changeCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changements',
      one: '1 changement',
      zero: '0 changement',
    );
    return '$_temp0';
  }

  @override
  String get filterActions => 'Filtrer les actions...';

  @override
  String get newestAtTop => 'Plus récent en haut';

  @override
  String get newestAtBottom => 'Plus récent en bas';

  @override
  String get noChanges => 'Aucun changement';

  @override
  String get diff => 'Différence';

  @override
  String get before => 'Avant';

  @override
  String get after => 'Après';

  @override
  String get noChangesDetected => 'Aucun changement détecté';

  @override
  String get noBenchmarks => 'Aucun benchmark';

  @override
  String get useBenchmarkSdk =>
      'Utilisez benchmarkStart/Step/Stop dans votre SDK pour mesurer les performances';

  @override
  String get benchmarksTitle => 'Benchmarks';

  @override
  String get searchBenchmarks => 'Rechercher des benchmarks...';

  @override
  String get total => 'Total';

  @override
  String get avg => 'Moy';

  @override
  String get min => 'Min';

  @override
  String get max => 'Max';

  @override
  String get p50 => 'P50';

  @override
  String get end => 'Fin';

  @override
  String stepsCount(Object count) {
    return 'Étapes ($count)';
  }

  @override
  String get noIntermediateSteps => 'Aucune étape intermédiaire enregistrée';

  @override
  String get noPerformanceData => 'Aucune donnée de performance';

  @override
  String get connectAppToProfile =>
      'Connectez une application avec DevConnect SDK pour démarrer le profilage';

  @override
  String get stopRecording => 'Arrêter l\'enregistrement';

  @override
  String get startRecording => 'Démarrer l\'enregistrement';

  @override
  String get performanceProfiler => 'Profileur de performance';

  @override
  String slowFrames(Object count) {
    return 'Images lentes : $count';
  }

  @override
  String get systemStatus => 'État du système';

  @override
  String get startup => 'Démarrage';

  @override
  String get battery => 'Batterie';

  @override
  String get emulator => 'Émulateur';

  @override
  String get drainRate => 'Taux de décharge';

  @override
  String get thermal => 'Thermique';

  @override
  String get diskRead => 'Lecture disque';

  @override
  String get diskWrite => 'Écriture disque';

  @override
  String get anr => 'ANR';

  @override
  String get charging => 'En charge';

  @override
  String get normal => 'Normal';

  @override
  String get fair => 'Moyen';

  @override
  String get serious => 'Sérieux';

  @override
  String get critical => 'Critique';

  @override
  String get reqs => 'requêtes';

  @override
  String get live => 'en direct';

  @override
  String get reqPerSec => 'req/s';

  @override
  String get err => 'err';

  @override
  String get waitingForRequests => 'En attente de requêtes...';

  @override
  String get waitingForData => 'En attente de données...';

  @override
  String get noMemoryLeaksDetected => 'Aucune fuite mémoire détectée';

  @override
  String get connectAppToMonitorLeaks =>
      'Connectez une application avec DevConnect SDK pour surveiller les fuites mémoire';

  @override
  String get memoryLeakDetection => 'Détection de fuites mémoire';

  @override
  String get warning => 'Avertissement';

  @override
  String get info => 'Info';

  @override
  String get detail => 'Détail';

  @override
  String get retainedSize => 'Taille retenue';

  @override
  String get timestamp => 'Horodatage';

  @override
  String get undisposedController => 'Controller non libéré';

  @override
  String get undisposedStream => 'Stream non libéré';

  @override
  String get undisposedTimer => 'Timer non libéré';

  @override
  String get undisposedAnimation => 'Animation non libérée';

  @override
  String get widgetLeak => 'Fuite de Widget';

  @override
  String get growingCollection => 'Collection croissante';

  @override
  String get custom => 'Personnalisé';

  @override
  String get smoothScrolling => 'Défilement fluide';

  @override
  String get smoothScrollingDesc =>
      'Rend le défilement de la molette de la souris plus fluide. Désactivez cette option si vous constatez des ralentissements ou une baisse de performance.';

  @override
  String get smoothScrollingDuration => 'Durée du défilement';

  @override
  String get smoothScrollingDurationDesc =>
      'La durée de l\'animation de défilement en millisecondes.';

  @override
  String binaryBody(String label) {
    return 'Le corps de $label est binaire';
  }

  @override
  String binaryBodySize(String kb, int bytes) {
    return '$kb ($bytes octets)';
  }

  @override
  String get binaryBodyHint =>
      'Identifiez l\'action via l\'en-tête X-Amz-Target.';

  @override
  String get openWithDefaultApp => 'Ouvrir avec l\'app par défaut';

  @override
  String get tipsAndShortcuts => 'Astuces & Raccourcis';

  @override
  String get tipsAndShortcutsDesc =>
      'Guides rapides pour les flux de travail les plus utiles. Cliquez sur une carte pour les détails.';

  @override
  String get tipAllEventsTitle => 'Flux de tous les événements';

  @override
  String get tipAllEventsBody =>
      'Une seule chronologie en direct des logs, requêtes réseau, changements de state, opérations de stockage et erreurs de votre appli, plus les événements display et async.';

  @override
  String get tipAllEventsSteps =>
      'Saisissez dans \"Rechercher des événements...\" pour trouver des messages, chemins d\'URL, actions, clés de stockage ou tags\nBasculez les puces \"LOG\", \"API\", \"STATE\" et \"STORE\" ; \"ERRORS\" ne garde que les erreurs et les requêtes en échec\nCliquez sur une ligne pour voir les détails ; \"Complet\" ou \"Tab\" les enregistre en image\nChoisissez un appareil, ou \"Tous\", dans la barre du bas pour définir quels événements s\'affichent\nUtilisez \"Plus ancien d\'abord\"/\"Plus récent d\'abord\" pour inverser l\'ordre et \"Défilement auto\" pour suivre les nouveaux événements';

  @override
  String get tipAllEventsTip =>
      '\"Tout effacer\" ici vide la liste de chaque page — Console, Network, State, Storage, Errors et les autres — pas seulement ce flux.';

  @override
  String get tipNetworkTitle => 'Inspecter le trafic réseau';

  @override
  String get tipNetworkBody =>
      'Les requêtes HTTP de votre appli, avec en-têtes, corps, statut et durée, ainsi que le trafic GraphQL, WebSocket et gRPC, et les requêtes auxquelles répond une règle de mock. gRPC vient uniquement du SDK Android.';

  @override
  String get tipNetworkSteps =>
      'Cliquez sur une requête pour ouvrir ses onglets \"Headers\", \"Request\", \"Response\" et \"Timing\"\nFiltrez par méthode, \"2xx\"/\"3xx\"/\"Erreurs\", ou saisissez une partie d\'URL dans \"Filtrer les URL...\"\nActivez \"Chercher aussi dans les corps de requête et de réponse\" pour fouiller le contenu des payloads\nAppuyez sur \"Copier cURL\" dans le panneau pour obtenir une commande curl ; clic droit sur une ligne pour \"Rejouer la requête\"\nOuvrez \"Protocols\" pour GraphQL, WebSocket et gRPC, ou \"Mock Audit\" pour les requêtes mockées';

  @override
  String get tipNetworkTip =>
      'Les tests de connectivité comme generate_204 et captive.apple.com restent masqués tant que votre recherche ne les cible pas.';

  @override
  String get tipConsoleTitle => 'Logs de la Console';

  @override
  String get tipConsoleBody =>
      'Les lignes de log de votre appli à mesure qu\'elles arrivent, avec niveau, tag et heure — appels console sur React Native, print et debugPrint sur Flutter, println sur Android.';

  @override
  String get tipConsoleSteps =>
      'Basculez \"DEBUG\", \"INFO\", \"WARN\" et \"ERROR\" pour afficher ou masquer chaque niveau\nSaisissez dans \"Rechercher dans les journaux...\" pour filtrer par texte du message ou par tag\nCliquez sur une ligne pour voir son tag, son message, ses métadonnées et sa stack trace, le cas échéant\nGardez \"Regrouper les logs répétés\" activé pour fusionner les lignes identiques consécutives en une seule ligne avec compteur\nUtilisez \"Exporter les logs\" pour enregistrer la liste filtrée en \"Texte (.txt)\" ou \"JSON (.json)\"';

  @override
  String get tipConsoleTip =>
      'Les lignes console.log, print et println ordinaires arrivent en niveau DEBUG — désactivez \"DEBUG\" pour ne garder que les infos, avertissements et erreurs.';

  @override
  String get tipStateTitle => 'Inspecteur d\'état';

  @override
  String get tipStateBody =>
      'Chaque changement de state signalé par votre appli, avec son action et le state avant et après — Redux, Zustand, MobX et d\'autres sur React Native ; BLoC, Riverpod et Provider sur Flutter ; ViewModels sur Android.';

  @override
  String get tipStateSteps =>
      'Ouvrez l\'onglet \"Timeline\" — il liste les changements de toutes les bibliothèques de state ; les puces de l\'en-tête affichent ou masquent chacune\nSaisissez dans \"Filtrer les actions...\" pour trouver une action ou un nom de store\nCliquez sur un changement, puis basculez entre \"Différence\", \"Avant\" et \"Après\"\nUtilisez \"Restaurer l\'état de l\'app à ce point\" (nécessite DevConnect.onStateRestore) ou \"Enregistrer comme instantané\"\nOuvrez \"Contrôles\" pour épingler des chemins de state, prendre des instantanés et dispatcher des actions Redux';

  @override
  String get tipStateTip =>
      '\"Différence\" ne se remplit que si le SDK en envoie une — Redux, Zustand et MobX le font ; Flutter et Android non, comparez donc \"Avant\" et \"Après\".';

  @override
  String get tipStorageTitle => 'Stockage de l\'appli';

  @override
  String get tipStorageBody =>
      'Chaque lecture, écriture et suppression sur les stores que vous enveloppez avec le SDK — AsyncStorage, MMKV, SharedPreferences, Hive et d\'autres — ainsi que les clés actuelles des stores pris en charge, modifiables ici.';

  @override
  String get tipStorageSteps =>
      'Dans \"Historique\", choisissez \"LECTURE\", \"ÉCRITURE\" ou \"SUPPRESSION\", et basculez les puces de store comme \"AS\" ou \"SP\"\nSaisissez une clé dans \"Filtrer les clés...\" pour voir toutes les opérations qui la concernent ; les valeurs sont aussi recherchées\nCliquez sur une ligne pour voir la valeur, la taille, le store et l\'heure de cette opération\nOuvrez \"Key-Value\" pour les clés actuelles d\'un store, puis \"Ajouter une clé\", \"Modifier la valeur\" ou \"Supprimer la clé\"\nAppuyez sur \"Recharger\" pour récupérer le contenu le plus récent de l\'appli';

  @override
  String get tipStorageTip =>
      '\"Tout effacer\" dans \"Historique\" ne vide que ce journal ; \"Tout effacer\" dans \"Key-Value\" supprime toutes les clés du store de l\'appli.';

  @override
  String get tipDatabaseTitle => 'Bases de données SQLite';

  @override
  String get tipDatabaseBody =>
      'Parcourez et interrogez les bases SQLite que votre appli enregistre avec DevConnect.registerDatabase : tables avec nombre de lignes, zone SQL et grille de résultats.';

  @override
  String get tipDatabaseSteps =>
      'Enregistrez la base dans l\'appli avec DevConnect.registerDatabase\nCliquez sur une table pour afficher un aperçu de ses 50 premières lignes\nModifiez le SQL et appuyez sur \"Exécuter\" pour lancer votre propre requête\nAppuyez de nouveau sur \"Exécuter\" pour relancer la requête — les résultats ne s\'actualisent pas tout seuls\nAppuyez sur \"Recharger les tables\" pour actualiser la liste des tables et le nombre de lignes';

  @override
  String get tipDatabaseTip =>
      'Pour trier, ajoutez ORDER BY à la requête — les en-têtes de colonne ne trient pas.';

  @override
  String get tipPerformanceTitle => 'Profileur de performance';

  @override
  String get tipPerformanceBody =>
      'Graphiques en direct du FPS, du CPU, de la mémoire et de l\'activité réseau de votre appli, plus les temps de frame, threads, batterie, état thermique, E/S disque, temps de démarrage et ANR lorsque le SDK les signale.';

  @override
  String get tipPerformanceSteps =>
      'Sélectionnez un appareil dans la barre du bas — avec \"Tous\" sélectionné, les graphiques mélangent les échantillons de toutes les applis\nLisez les pastilles \"FPS\", \"MEM\", \"CPU\" et \"SLOW\" en direct dans la barre d\'outils\nSurvolez un graphique pour lire la valeur exacte et le temps écoulé depuis sa réception\nConsultez \"État du système\" pour le temps de démarrage, la consommation de batterie, l\'état thermique, les E/S disque et les ANR\nUtilisez \"Capturer en image\" pour enregistrer les graphiques en PNG, et \"Effacer\" pour repartir de zéro';

  @override
  String get tipPerformanceTip =>
      'Survolez le badge rouge de la ligne FPS pour voir le temps moyen et le pire temps des frames lentes, ainsi que les cinq dernières frames lentes.';

  @override
  String get tipLeaksTitle => 'Détection de fuites mémoire';

  @override
  String get tipLeaksBody =>
      'Avertissements de fuite de votre appli : croissance continue de la mémoire détectée automatiquement par les trois SDK, plus de 50 timers actifs sur React Native, et tout ce que vous envoyez avec DevConnect.reportMemoryLeak.';

  @override
  String get tipLeaksSteps =>
      'Lisez les compteurs rouge, ambre et bleu dans la barre d\'outils : critique, avertissement et info\nCliquez sur une ligne pour voir son \"Détail\", sa \"Taille retenue\", sa \"Pile d\'exécution\" et ses \"Métadonnées\", lorsqu\'ils sont fournis\nConsultez \"Métadonnées\" sur les lignes de croissance mémoire pour voir chaque échantillon et la croissance totale en MB\nSignalez vos propres découvertes avec DevConnect.reportMemoryLeak, comme des controllers ou des streams non libérés\nAppuyez sur \"Effacer\", répétez le parcours suspect et surveillez les nouveaux avertissements';

  @override
  String get tipLeaksTip =>
      'Par défaut, la mémoire est échantillonnée toutes les 10 secondes ; un avertissement exige une croissance continue de plus de 20 MB, et au-delà de 40 MB il devient critique.';

  @override
  String get tipBenchmarkTitle => 'Benchmarks';

  @override
  String get tipBenchmarkBody =>
      'Mesure le temps du code que vous encadrez avec les appels benchmark du SDK, ainsi que les exécutions App Startup et App Background que chaque SDK enregistre de lui-même.';

  @override
  String get tipBenchmarkSteps =>
      'Encadrez le code avec DevConnect.benchmarkStart et benchmarkStop — sur React Native, on démarre avec benchmark\nMarquez les phases avec benchmarkStep (Flutter, React Native) ; les exécutions Android n\'ont pas d\'étapes\nCliquez sur une exécution pour voir \"Démarrer\", \"Fin\", \"Durée\" et un waterfall de ses étapes\nSaisissez dans \"Rechercher des benchmarks...\" pour filtrer la liste et la barre de statistiques\nAppuyez sur \"Capturer en image\" pour enregistrer le panneau d\'une exécution en PNG';

  @override
  String get tipBenchmarkTip =>
      'La barre de statistiques couvre toutes les exécutions listées — recherchez un seul titre pour obtenir \"Min\", \"Moy\" et \"P50\" de ce benchmark uniquement.';

  @override
  String get tipErrorsTitle => 'Erreurs';

  @override
  String get tipErrorsBody =>
      'Liste les erreurs signalées par votre appli : erreurs JavaScript et appels console.error de React Native, erreurs du framework Flutter et de Dart, et exceptions Android.';

  @override
  String get tipErrorsSteps =>
      'Flutter : démarrez l\'appli avec DevConnect.initAndRunApp — un simple init n\'installe aucun hook d\'erreur\nCliquez sur les puces \"JS\", \"Native\", \"Android\" et \"iOS\" pour afficher ou masquer une plateforme\nSaisissez dans \"Rechercher des erreurs...\" pour filtrer par message, source ou stack trace\nCliquez sur une erreur pour ouvrir ses onglets \"Message\", \"Stack Trace\" et \"Details\"\nSur une stack trace React Native, appuyez sur \"Symboliser\" pour faire correspondre les frames à votre source via Metro';

  @override
  String get tipErrorsTip =>
      'Les erreurs Flutter portent le tag Android ou iOS de l\'appareil sur lequel elles se sont produites — il n\'y a pas de puce Flutter distincte.';

  @override
  String get tipMockTitle => 'Mock Server';

  @override
  String get tipMockBody =>
      'Conserve de fausses réponses d\'API — méthode, regex d\'URL, statut, en-têtes, corps et délai facultatif — et les installe sur l\'appareil sélectionné, afin que les requêtes correspondantes n\'atteignent jamais le réseau.';

  @override
  String get tipMockSteps =>
      'Android : ajoutez d\'abord DevConnect.mockServerInterceptor() à votre OkHttpClient\nSélectionnez un appareil, appuyez sur \"Add rule\", remplissez les champs puis appuyez sur \"Save changes\"\nAppuyez sur \"Push all\" — les modifications, interrupteurs et suppressions qui suivent parviennent ensuite tout seuls à l\'appareil\nBasculez l\'interrupteur d\'une règle pour la mettre en pause, ou ouvrez-la et maintenez \"Hold to delete\" pour la supprimer (Undo la rétablit)\nAppuyez sur \"Clear device\" pour retirer toutes les règles de l\'appareil et arrêter la synchronisation';

  @override
  String get tipMockTip =>
      'Les règles ne vivent que dans la mémoire de DevConnect — quitter DevConnect les perd, mais un appareil synchronisé les récupère à sa reconnexion.';

  @override
  String get tipHistoryTitle => 'Historique des sessions';

  @override
  String get tipHistoryBody =>
      'Quand un appareil se déconnecte et reste absent 15 secondes, ses logs, appels réseau, changements de state et opérations de stockage restent ici sous forme de session en lecture seule, jusqu\'à sa reconnexion ou la fermeture de DevConnect.';

  @override
  String get tipHistorySteps =>
      'Cliquez sur une session pour ouvrir ses onglets \"All\", \"Logs\", \"Network\", \"State\" et \"Storage\"\nLisez l\'heure de déconnexion de chaque carte et son nombre d\'événements\nAppuyez sur le × d\'une carte pour supprimer cette session\nAppuyez sur \"Clear All\" pour vider la liste';

  @override
  String get tipHistoryTip =>
      'Une session disparaît dès que le même appareil — ou n\'importe quelle appli sur la même IP — se reconnecte ; consultez-la donc avant de relancer.';

  @override
  String get tipDisplayTitle => 'Display';

  @override
  String get tipDisplayBody =>
      'Affiche ce que votre appli envoie avec DevConnect.display() — un nom, un texte d\'aperçu facultatif, une valeur JSON et des métadonnées. Les trois SDK l\'offrent.';

  @override
  String get tipDisplaySteps =>
      'Appelez DevConnect.display avec un nom et, en option, une valeur, un aperçu et des métadonnées\nParcourez les lignes, les plus récentes en premier : chacune affiche le nom, l\'aperçu et l\'heure\nCliquez sur une ligne pour voir \"Preview\", \"Value\" au format JSON et \"Metadata\"\nAppuyez sur \"Clear all\" pour vider la liste';

  @override
  String get tipDisplayTip =>
      'Chaque appel ajoute une nouvelle ligne au lieu de remplacer la précédente — réutilisez un nom pour construire une chronologie.';

  @override
  String get tipAsyncTitle => 'Opérations asynchrones';

  @override
  String get tipAsyncBody =>
      'Liste les étapes asynchrones que votre appli signale avec DevConnect.reportAsyncOperation() — effets de saga, tâches, jobs en arrière-plan — avec statut, durée et résultat ou erreur. Rien n\'est suivi automatiquement.';

  @override
  String get tipAsyncSteps =>
      'Appelez reportAsyncOperation avec un type, une description et le statut start, resolve ou reject\nSur React Native, enveloppez une promise dans trackAsync pour la signaler du début à la fin\nLisez la couleur du badge : orange = démarrée, vert = résolue, rouge = rejetée\nCliquez sur une ligne pour voir ses détails, \"Result\" et \"Metadata\"\nAppuyez sur \"Clear all\" pour vider la liste';

  @override
  String get tipAsyncTip =>
      'Donnez le même sagaName aux appels liés — sélectionner l\'un d\'eux affiche tout le groupe sous \"Saga timeline\".';

  @override
  String get tipLayoutTitle => 'Inspecteur de Layout';

  @override
  String get tipLayoutBody =>
      'Capture l\'écran actuel de l\'appli avec son arbre d\'éléments — widgets Flutter, composants React Native ou vues Android — et affiche la position, la taille, le padding, la marge et les props de chaque élément.';

  @override
  String get tipLayoutSteps =>
      'Sélectionnez l\'appareil et appuyez sur \"Capturer\" pour récupérer son écran et son arbre d\'éléments\nSurvolez la capture d\'écran pour mettre un élément en surbrillance ; cliquez pour le sélectionner\nOu choisissez-le dans \"Arbre des éléments\", ou cherchez avec \"Rechercher par nom ou valeur\"\nActivez \"Éléments de l\'app uniquement\" pour masquer les widgets des bibliothèques (Flutter, React Native)\nLisez \"Propriétés\" — box model, position, taille et props — ou appuyez sur \"Copier en JSON\"';

  @override
  String get tipLayoutTip =>
      'React Native n\'envoie une capture d\'écran qu\'après l\'appel de DevConnect.registerScreenshot() — sans cela, vous n\'obtenez que des contours.';

  @override
  String get settingsGroupConnection => 'Connexion';

  @override
  String get settingsGroupConnectionDesc => 'Serveur, adresses réseau et USB.';

  @override
  String get settingsGroupDevices => 'Appareils';

  @override
  String get settingsGroupDevicesDesc =>
      'Applis connectées et appareils déjà vus.';

  @override
  String get settingsGroupAppearance => 'Apparence';

  @override
  String get settingsGroupAppearanceDesc =>
      'Thème, langue et onglets affichés.';

  @override
  String get settingsGroupData => 'Affichage et données';

  @override
  String get settingsGroupDataDesc =>
      'Affichage des détails et historique conservé.';

  @override
  String get settingsGroupGuides => 'Guides';

  @override
  String get settingsGroupGuidesDesc => 'Démarrage, raccourcis et astuces.';

  @override
  String get settingsGroupSupport => 'Soutenir';

  @override
  String get settingsGroupSupportDesc => 'Aidez DevConnect à continuer.';

  @override
  String get tipsTabFeatures => 'Fonctions';

  @override
  String get tipsTabShortcuts => 'Raccourcis';

  @override
  String get tipsTabConnect => 'Connecter un appareil';

  @override
  String get tipsTabSdk => 'Installer le SDK';

  @override
  String get tipsTabAdvanced => 'Avancé';

  @override
  String get tipsSteps => 'Étapes';

  @override
  String get tipsKeys => 'Touches';

  @override
  String get tipsProTip => 'Astuce';

  @override
  String get tipsPrevious => 'Précédent';

  @override
  String get tipsNext => 'Suivant';

  @override
  String get tipsDone => 'Terminé';

  @override
  String get tipsOpenPage => 'Ouvrir la page';

  @override
  String get tipsCopyCode => 'Copier';

  @override
  String get tipsCodeCopied => 'Code copié';

  @override
  String get tipsClose => 'Fermer';

  @override
  String get pageGuide => 'Comment utiliser cette page';

  @override
  String get guideReloadTitle => 'Recharger l\'appli';

  @override
  String get guideReloadSummary =>
      'Rechargez l\'appli inspectée depuis n\'importe quelle page de DevConnect, même en pleine saisie : Flutter reconstruit ses widgets, React Native recharge depuis Metro, Android recrée l\'activity en cours.';

  @override
  String get guideReloadSteps =>
      '[⌘ R] Recharger l\'appli sélectionnée, ou toutes les applis connectées si aucune n\'est sélectionnée\n[⇧ ⌘ R] Hot restart : exécute onHotRestartRequest pour une appli Flutter, sinon recharge comme ⌘ R\nOu cliquez sur les boutons de rechargement de la barre du bas — leurs infobulles indiquent le raccourci';

  @override
  String get guideReloadTip =>
      'Le ⌘ R de Flutter reconstruit l\'arbre de widgets et conserve le state, mais ne charge pas les modifications de code — utilisez pour cela le hot reload de votre IDE.';

  @override
  String get guideJsonSearchTitle => 'Rechercher dans un corps';

  @override
  String get guideJsonSearchSummary =>
      'Tree, JSON et la vue code (TypeScript, Dart ou Kotlin) ont chacun leur propre recherche : elle ignore la casse, surligne chaque résultat et défile jusqu\'au résultat courant.';

  @override
  String get guideJsonSearchSteps =>
      '[⌘ F] Aller au champ de recherche de la vue — cliquez d\'abord dans le corps\n[↵] Aller au résultat suivant\n[⇧ ↵] Aller au résultat précédent\n[Esc] Effacer la recherche';

  @override
  String get guideJsonSearchTip =>
      'La recherche de Tree déplie les nœuds et charge les pages suivantes pour afficher jusqu\'à 500 résultats ; JSON en compte jusqu\'à 100 000.';

  @override
  String get guideLayoutZoomTitle => 'Zoomer sur une capture';

  @override
  String get guideLayoutZoomSummary =>
      'Zoomez et cadrez une capture de la page Layout au clavier — les touches fonctionnent dès qu\'une capture est affichée.';

  @override
  String get guideLayoutZoomSteps =>
      '[⌘ +] Zoom avant, 1,25× à chaque appui\n[⌘ −] Zoom arrière\n[⌘ 0] Taille réelle : 100 % correspond à la taille de l\'écran de l\'appli\n[⌘ 1] Ajuster tout l\'écran au panneau\n[⌘ 2] Zoomer sur l\'élément sélectionné';

  @override
  String get guideLayoutZoomTip =>
      'Cliquez sur le pourcentage de zoom pour choisir 50, 100, 200 ou 400 % ; pincez pour zoomer et faites glisser pour vous déplacer.';

  @override
  String get guideLayoutMeasureTitle => 'Mesurer les espacements';

  @override
  String get guideLayoutMeasureSummary =>
      'Maintenez Option pour voir les distances entre l\'élément sélectionné et celui sous le pointeur, comme dans les outils de design.';

  @override
  String get guideLayoutMeasureSteps =>
      'Sélectionnez un élément : cliquez dessus sur la capture ou choisissez-le dans l\'arbre\n[⌥] Maintenez Option et pointez un autre élément\nLisez les écarts entre éléments séparés, ou les marges internes quand l\'un contient l\'autre\nRelâchez Option pour revoir le box model de l\'élément survolé';

  @override
  String get guideLayoutMeasureTip =>
      'Des éléments qui se chevauchent n\'affichent aucune distance — la mesure exige qu\'un élément soit à l\'intérieur de l\'autre, ou qu\'il y ait un espace entre eux.';

  @override
  String get guideLayoutTreeTitle => 'Parcourir l\'arbre des éléments';

  @override
  String get guideLayoutTreeSummary =>
      'Parcourez l\'arbre d\'éléments capturé avec les touches fléchées dès qu\'il a le focus — cliquez sur une ligne ou sur un élément de la capture.';

  @override
  String get guideLayoutTreeSteps =>
      '[↑ ↓] Passer à la ligne du dessus ou du dessous\n[→] Ouvrir la ligne ; appuyer encore pour entrer dans son premier enfant\n[←] Fermer la ligne ; appuyer encore pour remonter à son parent\n[Esc] Effacer la sélection';

  @override
  String get guideLayoutTreeTip =>
      'Saisissez dans \"Rechercher par nom ou valeur\" pour chercher dans les noms, props et state ; ↵ et ⇧ ↵ parcourent les résultats.';

  @override
  String get guideAndroidEmulatorTitle => 'Émulateur Android';

  @override
  String get guideAndroidEmulatorSummary =>
      'Les applis de l\'émulateur Android joignent ce Mac via 10.0.2.2 (Genymotion : 10.0.3.2), donc rien à configurer.';

  @override
  String get guideAndroidEmulatorSteps =>
      'Vérifiez que Paramètres › \"Connexion\" › \"Serveur\" affiche \"Serveur en cours\"\nAndroid natif : passez enabled = BuildConfig.DEBUG à installForApp — c\'est désactivé par défaut\nLancez une version debug dans l\'émulateur ; adb reverse n\'est pas nécessaire\nRetrouvez l\'appli dans la barre des appareils, en bas de la fenêtre';

  @override
  String get guideAndroidEmulatorTip =>
      'DevConnect démarre sur le port 9090 à chaque lancement ; un port modifié sous \"Serveur\" ne tient que jusqu\'à la fermeture de DevConnect, et le port du SDK doit correspondre.';

  @override
  String get guideAndroidUsbTitle => 'Téléphone Android en USB';

  @override
  String get guideAndroidUsbSummary =>
      'adb reverse redirige le localhost du téléphone vers ce Mac par le câble, de sorte que l\'appli se connecte sans Wi‑Fi.';

  @override
  String get guideAndroidUsbSteps =>
      'Activez le débogage USB, branchez le téléphone et autorisez ce Mac quand on vous le demande\nAppuyez sur \"Exécuter ADB Reverse\" dans Paramètres › \"Connexion\" › \"Connexion USB\", ou lancez la commande ci-dessous\nDémarrez l\'appli — redémarrez une appli Android native qui tournait déjà\nPas de connexion ? Appuyez sur \"Appareils\" à cet endroit pour vérifier qu\'adb voit le téléphone';

  @override
  String get guideAndroidUsbTip =>
      'Relancez-le après un rebranchement, un redémarrage d\'adb ou de la machine ; avec plusieurs appareils branchés, lancez adb -s avec le numéro de série du téléphone dans Terminal.';

  @override
  String get guideIosSimulatorTitle => 'Simulateur iOS';

  @override
  String get guideIosSimulatorSummary =>
      'Le simulateur partage le réseau du Mac : une version debug joint DevConnect sur localhost sans aucune configuration.';

  @override
  String get guideIosSimulatorSteps =>
      'Vérifiez que Paramètres › \"Connexion\" › \"Serveur\" affiche \"Serveur en cours\"\nLancez une version debug de l\'appli dans le simulateur\nRetrouvez-la dans la barre des appareils, en bas de la fenêtre';

  @override
  String get guideIosSimulatorTip =>
      'L\'ordre de démarrage n\'a pas d\'importance : les applis React Native et Flutter réessaient en boucle, donc elles se connectent quelques secondes après le démarrage de DevConnect.';

  @override
  String get guideIphoneTitle => 'iPhone';

  @override
  String get guideIphoneSummary =>
      'Sur le même Wi‑Fi que le Mac, une version debug trouve généralement DevConnect toute seule ; sinon, indiquez l\'adresse du Mac comme host.';

  @override
  String get guideIphoneSteps =>
      'Mettez l\'iPhone et le Mac sur le même Wi‑Fi — les réseaux invités bloquent souvent cela\nLancez la version debug et autorisez l\'accès au réseau local quand iOS le demande\nPatientez quelques secondes : React Native trouve le Mac via Metro, Flutter par diffusion réseau\nAbsente de la liste ? Copiez l\'adresse du Mac depuis Paramètres › \"Connexion\" › \"Réseau\"\nIndiquez-la comme host dans l\'init du SDK (code ci-dessous), puis redémarrez l\'appli';

  @override
  String get guideIphoneTip =>
      'Un câble USB seul ne peut pas connecter une appli iPhone — le téléphone doit joindre le Mac par le réseau.';

  @override
  String get guideTroubleshootTitle => 'L\'appli ne se connecte pas';

  @override
  String get guideTroubleshootSummary =>
      'La plupart des problèmes de connexion tiennent à quelques causes — vérifiez-les dans cet ordre.';

  @override
  String get guideTroubleshootSteps =>
      'Paramètres › \"Connexion\" › \"Serveur\" affiche \"Serveur en cours\" et aucune erreur de port\nL\'appli est une version debug ; Android natif exige aussi enabled = BuildConfig.DEBUG\nLe port du SDK correspond à celui du serveur — les deux commencent à 9090\nLes téléphones sont sur le même Wi‑Fi que le Mac, ou le port d\'Android est redirigé avec adb reverse\nSur Wi‑Fi, macOS autorise DevConnect à accepter les connexions entrantes (Réglages Système › Réseau › Pare-feu)';

  @override
  String get guideTroubleshootTip =>
      'Toujours bloqué ? Indiquez comme host une adresse de Paramètres › \"Connexion\" › \"Réseau\" et passez auto: false (Flutter : auto_: false) pour que les reconnexions la conservent.';

  @override
  String get guideSdkReactNativeSummary =>
      'Installez le paquet et appelez init une fois au démarrage — fetch et XHR (donc axios aussi), logs console, erreurs et performances sont capturés à partir de là.';

  @override
  String get guideSdkReactNativeSteps =>
      'Ajoutez devconnect-manage-kit avec yarn ou npm (commandes ci-dessous)\nAppelez DevConnect.init une fois au démarrage, avant la première requête\nPour le state, ajoutez devConnectReduxMiddleware (Redux), devConnectMiddleware (Zustand) ou setupMobxSpy (MobX)\nLancez une version debug — init ne fait rien en release sauf si vous passez enabled: true';

  @override
  String get guideSdkReactNativeTip =>
      'init ne s\'exécute qu\'une fois par démarrage de l\'appli ; après avoir changé host ou port, faites un rechargement complet — Fast Refresh conserve les anciens réglages.';

  @override
  String get guideSdkFlutterSummary =>
      'Démarrez l\'appli via initAndRunApp : le HTTP de dart:io (http, Dio, Chopper…), print et debugPrint, les erreurs et les performances sont capturés sans code supplémentaire.';

  @override
  String get guideSdkFlutterSteps =>
      'Exécutez flutter pub add devconnect_manage_kit\nDémarrez l\'appli avec DevConnect.initAndRunApp dans main(), en passant un callback runApp asynchrone\nPour Riverpod ou BLoC, appelez DevConnect.reportStateChange ou reportBlocChange depuis votre observer\nLancez une version debug — les versions profile et release restent désactivées';

  @override
  String get guideSdkFlutterTip =>
      'Placez Firebase et le reste du code de démarrage dans le callback runApp — appeler ensureInitialized() avant initAndRunApp provoque une incohérence de zone (zone mismatch).';

  @override
  String get guideSdkAndroidSummary =>
      'Ajoutez la dépendance Maven Central et appelez installForApp dans Application.onCreate : la sortie de println, les crashes, les ANR, les performances et le state des ViewModels sont capturés ; le HTTP exige l\'intercepteur OkHttp.';

  @override
  String get guideSdkAndroidSteps =>
      'Ajoutez io.github.buivietphi:devconnect-android:1.1.0 à app/build.gradle.kts\nAppelez DevConnect.installForApp dans Application.onCreate avec enabled = BuildConfig.DEBUG — c\'est désactivé par défaut\nAjoutez DevConnect.okHttpInterceptor() à chaque OkHttpClient, y compris celui de Retrofit\nLoguez avec DCLog au lieu de android.util.Log ; pour Timber, plantez un Tree qui appelle DevConnectTimberHelper.log\nVérifiez que le manifeste de l\'appli demande la permission INTERNET';

  @override
  String get guideSdkAndroidTip =>
      'Le SDK ne cherche DevConnect qu\'une seule fois, au lancement — démarrez d\'abord DevConnect (et adb reverse), ou redémarrez l\'appli.';

  @override
  String get guideMockApiTitle => 'Simuler une API';

  @override
  String get guideMockApiSummary =>
      'Répondez aux requêtes correspondantes avec votre propre statut, vos en-têtes et votre corps, éventuellement retardés, sans toucher au serveur ni à l\'appli.';

  @override
  String get guideMockApiSteps =>
      'Sélectionnez un appareil dans la barre du bas, ouvrez \"Mock Server\" et appuyez sur \"Add rule\"\nRenseignez \"Method\", \"Status\", \"URL pattern\" (une regex appliquée n\'importe où dans l\'URL) et le corps\nAppuyez sur \"Save changes\", puis sur \"Push all\" — toute la liste de règles est envoyée, et les enregistrements suivants parviennent seuls à l\'appareil\nConsultez Network › \"Mock Audit\" pour voir les requêtes auxquelles une règle a répondu\nUtilisez l\'interrupteur d\'une règle pour la mettre en pause, ou \"Clear device\" pour retirer toutes les règles';

  @override
  String get guideMockApiTip =>
      'Android exige DevConnect.mockServerInterceptor() sur OkHttp ; React Native ne simule que les appels fetch, pas axios ni XMLHttpRequest.';

  @override
  String get guideStateControlsTitle => 'Piloter l\'état depuis le bureau';

  @override
  String get guideStateControlsSummary =>
      'L\'onglet Controls du State Inspector suit des chemins d\'état, enregistre des snapshots à renvoyer et envoie des actions à l\'app.';

  @override
  String get guideStateControlsSteps =>
      'Choisissez un appareil dans la barre du bas, ouvrez State Inspector puis l\'onglet \"Controls\"\nSubscriptions : épinglez un chemin comme auth.user.name ; fonctionne sur toutes les plateformes sans code dans l\'app\nSnapshots : \"Take snapshot\" enregistre le dernier état ; \"Restore\" le renvoie dès que l\'app gère onStateRestore\nDispatch action : saisissez un objet JSON avec un \"type\" comme \"LOGOUT\" puis appuyez sur \"Dispatch\" ; React Native nécessite connectReduxStore(store), Flutter et Android onReduxDispatch\nLes changements qu\'ils provoquent apparaissent dans \"Timeline\" quand la bibliothèque de state de l\'app les signale';

  @override
  String get guideStateControlsTip =>
      'Subscriptions lit le dernier état signalé : tout le store avec Redux, mais seulement le store ou provider modifié en dernier avec Zustand, MobX, Riverpod ou un ViewModel. Si Restore ou Dispatch ne fait rien, l\'app n\'a pas défini son handler ; un handler qui lève une erreur s\'affiche dans la Console.';

  @override
  String get guideNetworkConditionsTitle => 'Réseau lent ou hors ligne';

  @override
  String get guideNetworkConditionsSummary =>
      'Retardez les requêtes HTTP des applis ou faites-les échouer, sans toucher aux réglages de l\'appareil — la connexion propre à DevConnect continue de fonctionner.';

  @override
  String get guideNetworkConditionsSteps =>
      'Dans Network, ouvrez le menu à icône de jauge \"Conditions réseau\" de la barre d\'outils\nChoisissez \"Lent (+500 ms)\" ou \"3G lente (~2 s)\" pour retarder chaque requête\nChoisissez \"Hors ligne\" pour faire échouer les requêtes aussitôt, comme avec un réseau coupé\nChoisissez \"Normal\" quand vous avez terminé — l\'icône reste en surbrillance jusque-là\nSur Android, seul le trafic OkHttp est ralenti, via DevConnect.okHttpInterceptor()';

  @override
  String get guideNetworkConditionsTip =>
      'Il s\'applique à toutes les applis connectées, et à celles qui se connectent plus tard, jusqu\'à ce que vous choisissiez \"Normal\".';

  @override
  String get guideReplayTitle => 'Rejouer une requête';

  @override
  String get guideReplaySummary =>
      'Faites renvoyer par l\'appli une requête capturée — même méthode, URL, en-têtes et corps — sans repasser par ses écrans.';

  @override
  String get guideReplaySteps =>
      'Dans Network, faites un clic droit sur une requête et choisissez \"Rejouer la requête\"\nOu ouvrez la requête et cliquez sur l\'icône de répétition dans son en-tête\nLa requête rejouée apparaît comme une nouvelle ligne dans la liste';

  @override
  String get guideReplayTip =>
      'Android rejoue les appels OkHttp récents via le client et les intercepteurs propres à l\'appli ; Flutter et React Native renvoient tels quels les en-têtes capturés.';

  @override
  String get guideHarExportTitle => 'Exporter en HAR';

  @override
  String get guideHarExportSummary =>
      'Enregistrez les requêtes listées par Network dans un fichier HAR 1.2 standard — en-têtes, corps, statut et temps inclus — à ouvrir dans d\'autres outils.';

  @override
  String get guideHarExportSteps =>
      'Affinez la liste \"HTTP\" avec les filtres d\'appareil, de méthode, de statut et d\'URL\nCliquez sur l\'icône de téléchargement \"Exporter les requêtes affichées en HAR\" dans la barre d\'outils\nChoisissez où enregistrer le fichier .har\nOuvrez-le dans Chrome DevTools ou Charles, ou partagez-le avec votre équipe';

  @override
  String get guideHarExportTip =>
      'Seul ce que la liste HTTP affiche est enregistré : vos filtres déterminent donc le contenu du fichier ; les entrées \"Protocols\" ne sont pas incluses.';

  @override
  String get guideDatabaseQueryTitle => 'Interroger la base de l\'appli';

  @override
  String get guideDatabaseQuerySummary =>
      'Parcourez les tables d\'une base SQLite de l\'appli et exécutez-y du SQL, directement depuis DevConnect.';

  @override
  String get guideDatabaseQuerySteps =>
      'Enregistrez la base dans l\'appli avec DevConnect.registerDatabase (extraits de code ci-dessous)\nOuvrez Database et cliquez sur une table pour afficher un aperçu de ses 50 premières lignes\nModifiez le SQL et appuyez sur \"Exécuter\" — les résultats s\'arrêtent à 1 000 lignes\nCliquez sur \"Recharger les tables\" après que l\'appli a modifié ses tables';

  @override
  String get guideDatabaseQueryTip =>
      'Les requêtes s\'exécutent sur la base de la dernière table sur laquelle vous avez cliqué, sinon sur la première base enregistrée.';

  @override
  String get guideBigJsonTitle => 'Corps volumineux';

  @override
  String get guideBigJsonSummary =>
      'Les gros corps s\'ouvrent sans figer DevConnect : ils sont analysés en arrière-plan, et Tree et JSON ne construisent que ce qui est à l\'écran.';

  @override
  String get guideBigJsonSteps =>
      'Cliquez sur \"Afficher … de plus\" sous une longue liste Tree pour charger les 200 éléments suivants\nUtilisez \"Copier la valeur\" sur les longues chaînes de Tree — Tree n\'en affiche que les 2 000 premiers caractères\nPassez à JSON pour faire défiler et rechercher dans tout le document\nUtilisez \"Copy JSON\" ou \"Save as file\" à cet endroit — les deux prennent le corps complet\nLes lignes JSON de plus de 20 000 caractères n\'affichent que leur début ; copiez ou enregistrez pour tout obtenir';

  @override
  String get guideBigJsonTip =>
      'Quand le corps est une liste d\'objets, Tree propose \"Tableau\" : il affiche 500 lignes, mais \"Télécharger le tableau (CSV)\" enregistre toutes les lignes correspondantes.';

  @override
  String get guideCustomCommandsTitle => 'Commandes personnalisées';

  @override
  String get guideCustomCommandsSummary =>
      'Exécutez du code dans l\'appli depuis DevConnect — vider un cache, se déconnecter, créer des données de test — et voyez ce qu\'il renvoie.';

  @override
  String get guideCustomCommandsSteps =>
      'Enregistrez un handler dans l\'appli avec DevConnect.registerCommand (extraits de code ci-dessous)\nOuvrez \"Commandes personnalisées\" et cliquez sur une commande listée par l\'appli, ou saisissez son nom\nAjoutez des arguments sous forme d\'objet JSON si la commande en a besoin\nAppuyez sur \"Exécuter\", ou sur ↵ dans le champ \"Commande\", et lisez le résultat en dessous';

  @override
  String get guideCustomCommandsTip =>
      'Les handlers Flutter et React Native peuvent être asynchrones ; une erreur levée s\'affiche comme résultat, et sans réponse l\'appel expire au bout de 10 secondes.';

  @override
  String get restart => 'Redémarrer';

  @override
  String get serverAddressHint => 'Les applis se connectent à cette adresse.';

  @override
  String get serverStoppedHint =>
      'Démarrez le serveur pour que les applis puissent se connecter.';

  @override
  String get tabBenchmark => 'Benchmark';

  @override
  String get tabDisplay => 'Affichage';

  @override
  String get tabAsync => 'Opérations asynchrones';

  @override
  String get tabLayout => 'Inspecteur de mise en page';

  @override
  String get tabCommands => 'Commandes personnalisées';

  @override
  String get tabMockServer => 'Serveur mock';

  @override
  String get tabsAlwaysShown =>
      'Tous les événements et Paramètres restent toujours visibles.';

  @override
  String get quickStartDesc =>
      'Installez le SDK, lancez-le dans l\'appli, puis connectez-vous.';

  @override
  String get quickStartNext => 'Ensuite — lancez-le dans l\'appli';

  @override
  String get quickStartEmulator => 'Les émulateurs se connectent seuls';

  @override
  String get quickStartWifi => 'Téléphone en Wi‑Fi';

  @override
  String get quickStartUsb => 'Android en USB';
}
