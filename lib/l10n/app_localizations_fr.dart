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
      'WiFi se connecte automatiquement sur le même réseau. USB : installer iproxy.';

  @override
  String get quickStart => 'Démarrage rapide';

  @override
  String get quickStartDesc =>
      'Trois étapes pour connecter votre application. Cliquez sur un onglet de plateforme pour voir l\'extrait correspondant.';

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
    return '$kb Ko ($bytes octets)';
  }

  @override
  String get binaryBodyHint =>
      'Identifiez l\'action via l\'en-tête X-Amz-Target.';
}
