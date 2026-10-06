import 'package:flutter/material.dart';
import '../theme.dart';

// ── Public entry point ─────────────────────────────────────────────────────────

void showLegalSheet(BuildContext context) {
  final t = PintThemeProvider.of(context);
  final nav = Navigator.of(context);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetCtx) => _LegalSheet(
      t: t,
      onOpen: (title, sections) {
        Navigator.of(sheetCtx).pop();
        nav.push(
          MaterialPageRoute(
            builder: (_) =>
                _LegalContentScreen(title: title, sections: sections),
          ),
        );
      },
    ),
  );
}

// ── Bottom sheet ───────────────────────────────────────────────────────────────

class LegalSheet extends StatelessWidget {
  final PintTheme t;
  const LegalSheet({super.key, required this.t});

  @override
  Widget build(BuildContext context) => _LegalSheet(
    t: t,
    onOpen: (title, sections) => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _LegalContentScreen(title: title, sections: sections),
      ),
    ),
  );
}

class _LegalSheet extends StatelessWidget {
  final PintTheme t;
  final void Function(String title, List<_Section> sections) onOpen;

  const _LegalSheet({required this.t, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: t.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: t.textFaint,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Text(
                'Rechtliches',
                style: TextStyle(
                  color: t.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              LegalTile(
                t: t,
                icon: Icons.privacy_tip_outlined,
                label: 'Datenschutzerklärung',
                onTap: () => onOpen('Datenschutzerklärung', _kPrivacy),
              ),
              const SizedBox(height: 8),
              LegalTile(
                t: t,
                icon: Icons.gavel_outlined,
                label: 'Nutzungsbedingungen',
                onTap: () => onOpen('Nutzungsbedingungen', _kTerms),
              ),
              const SizedBox(height: 8),
              LegalTile(
                t: t,
                icon: Icons.info_outline,
                label: 'Impressum',
                onTap: () => onOpen('Impressum', _kImpressum),
              ),
              const SizedBox(height: 8),
              LegalTile(
                t: t,
                icon: Icons.forum_outlined,
                label: 'Community-Regeln',
                onTap: () => onOpen('Community-Regeln', _kCommunityRules),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Content screen ─────────────────────────────────────────────────────────────

class _Section {
  final String? heading;
  final String body;
  const _Section({this.heading, required this.body});
}

class _LegalContentScreen extends StatelessWidget {
  final String title;
  final List<_Section> sections;

  const _LegalContentScreen({required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: t.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: t.text,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: t.divider),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 60),
        itemCount: sections.length,
        itemBuilder: (_, i) {
          final s = sections[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (s.heading != null) ...[
                  Text(
                    s.heading!,
                    style: TextStyle(
                      color: t.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  s.body,
                  style: TextStyle(
                    color: t.textMuted,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── LegalTile ──────────────────────────────────────────────────────────────────

class LegalTile extends StatelessWidget {
  final PintTheme t;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const LegalTile({
    super.key,
    required this.t,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: t.surfaceWeak,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: t.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: t.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: t.textFaint),
          ],
        ),
      ),
    );
  }
}

// ── Legal content ──────────────────────────────────────────────────────────────

const _kImpressum = [
  _Section(
    body:
        'Angaben gemäß § 5 DDG\n\n'
        'Maximilian Engl\n'
        'Am Tennenbach 26\n'
        '91080 Spardorf\n'
        'Deutschland\n\n'
        'E-Mail: engl.devmail@gmail.com',
  ),
  _Section(
    heading: 'Verantwortlich für den Inhalt gemäß § 18 Abs. 2 MStV',
    body:
        'Maximilian Engl\n'
        'Am Tennenbach 26\n'
        '91080 Spardorf\n'
        'Deutschland',
  ),
  _Section(
    heading: 'EU-Streitschlichtung',
    body:
        'Die Europäische Kommission stellt eine Plattform zur Online-Streitbeilegung (OS) bereit. '
        'Die Plattform ist unter folgendem Link erreichbar: https://ec.europa.eu/consumers/odr/\n\n'
        'Wir sind nicht verpflichtet und nicht bereit, an einem Streitbeilegungsverfahren vor einer '
        'Verbraucherschlichtungsstelle teilzunehmen.',
  ),
  _Section(
    heading: 'Haftung für Inhalte',
    body:
        'Als Diensteanbieter bin ich gemäß § 7 Abs. 1 DDG für eigene Inhalte nach den allgemeinen Gesetzen verantwortlich. '
        'Für fremde Inhalte, insbesondere von Nutzern veröffentlichte Beiträge, Kommentare und Bilder, besteht keine allgemeine '
        'Pflicht zur Überwachung. Rechtswidrige oder gegen die Community-Regeln verstoßende Inhalte können gemeldet werden und werden nach Kenntnis geprüft.',
  ),
  _Section(
    heading: 'Kontakt',
    body:
        'Bei Fragen zur App Zapfen, zu rechtlichen Themen oder zur Meldung von Problemen kannst du dich per E-Mail an '
        'engl.devmail@gmail.com wenden.',
  ),
];

const _kPrivacy = [
  _Section(
    body:
        'Stand: Juni 2026\n\n'
        'Diese Datenschutzerklärung informiert dich gemäß Art. 13 DSGVO darüber, welche personenbezogenen Daten bei der Nutzung der App Zapfen verarbeitet werden. '
        'Zapfen ist eine Social-App zum Entdecken und Bewerten von Getränken jeder Art.',
  ),
  _Section(
    heading: '1. Verantwortlicher',
    body:
        'Maximilian Engl\n'
        'Am Tennenbach 26\n'
        '91080 Spardorf\n'
        'Deutschland\n\n'
        'E-Mail: engl.devmail@gmail.com',
  ),
  _Section(
    heading: '2. Verarbeitete personenbezogene Daten',
    body:
        'Bei der Nutzung von Zapfen können folgende Daten verarbeitet werden:\n\n'
        '• Kontodaten: E-Mail-Adresse, Benutzername und verschlüsseltes Passwort\n'
        '• Profildaten: Profilbild und öffentlich sichtbare Profilinformationen, soweit du diese angibst\n'
        '• Inhalte: Beiträge, Bilder, Bildunterschriften, Kommentare und Reaktionen\n'
        '• Soziale Daten: Freundschaften, Freundschaftsanfragen, Blockierungen und Interaktionen mit anderen Nutzern\n'
        '• Meldedaten: gemeldete Beiträge, Meldegründe und Bearbeitungsstatus von Meldungen\n'
        '• Standortdaten: nur optional und nur, wenn du eine Standortfunktion aktiv nutzt oder erlaubst\n'
        '• Push-Daten: Push-Benachrichtigungstoken, sofern du Push-Benachrichtigungen erlaubst\n'
        '• Technische Daten: IP-Adresse, Zeitstempel, angeforderte Ressourcen, Geräteinformationen und Server-Logs',
  ),
  _Section(
    heading: '3. Zwecke der Verarbeitung',
    body:
        'Die Daten werden zu folgenden Zwecken verarbeitet:\n\n'
        '• Registrierung, Login und Verwaltung deines Benutzerkontos\n'
        '• Bereitstellung der App-Funktionen\n'
        '• Anzeige von Profilen, Beiträgen, Bildern, Kommentaren und Reaktionen\n'
        '• Verwaltung von Freundschaften, Blockierungen und sozialen Interaktionen\n'
        '• Bereitstellung von Melde- und Moderationsfunktionen\n'
        '• Versand von Push-Benachrichtigungen nach deiner Einwilligung\n'
        '• Gewährleistung der Sicherheit, Stabilität und Missbrauchsprävention\n'
        '• Erfüllung gesetzlicher Pflichten',
  ),
  _Section(
    heading: '4. Rechtsgrundlagen',
    body:
        'Die Verarbeitung erfolgt auf folgenden Rechtsgrundlagen:\n\n'
        '• Art. 6 Abs. 1 lit. b DSGVO: Verarbeitung zur Erfüllung des Nutzungsverhältnisses, insbesondere für Registrierung, Login, Profil, Beiträge, Kommentare, Freundschaften und Grundfunktionen der App.\n'
        '• Art. 6 Abs. 1 lit. a DSGVO: Verarbeitung aufgrund deiner Einwilligung, insbesondere bei optionalen Standortdaten und Push-Benachrichtigungen. Du kannst deine Einwilligung jederzeit mit Wirkung für die Zukunft widerrufen.\n'
        '• Art. 6 Abs. 1 lit. f DSGVO: Verarbeitung aufgrund berechtigter Interessen, insbesondere für Sicherheit, Fehleranalyse, Missbrauchsprävention, Moderation und Schutz der Community.\n'
        '• Art. 6 Abs. 1 lit. c DSGVO: Verarbeitung zur Erfüllung rechtlicher Pflichten, soweit solche Pflichten bestehen.',
  ),
  _Section(
    heading: '5. Standortdaten',
    body:
        'Standortdaten werden nur verarbeitet, wenn du eine entsprechende Funktion aktiv nutzt oder die Standortfreigabe erlaubst. '
        'Die Nutzung der App ist grundsätzlich auch ohne Standortfreigabe möglich. Du kannst die Berechtigung jederzeit in den Einstellungen deines Geräts widerrufen.',
  ),
  _Section(
    heading: '6. Push-Benachrichtigungen',
    body:
        'Zapfen kann Push-Benachrichtigungen verwenden, zum Beispiel für soziale Interaktionen, Freundschaftsanfragen oder relevante App-Hinweise. '
        'Push-Benachrichtigungen erfolgen nur, wenn du sie erlaubst. Du kannst sie jederzeit in den Geräteeinstellungen deaktivieren. '
        'Für den Versand wird Firebase Cloud Messaging von Google verwendet.',
  ),
  _Section(
    heading: '7. Speicherung von Bildern und Medien',
    body:
        'Von dir hochgeladene Bilder, Profilbilder und sonstige Medieninhalte werden über Supabase Storage gespeichert. '
        'Diese Inhalte können anderen Nutzern innerhalb der App angezeigt werden, sofern sie Teil deines Profils, deiner Beiträge oder deiner Kommentare sind.',
  ),
  _Section(
    heading: '8. Eingesetzte Dienste und Empfänger',
    body:
        'Zur Bereitstellung der App werden folgende Dienste eingesetzt:\n\n'
        '• MongoDB: Speicherung von Nutzerkonten, Beiträgen, Kommentaren, Freundschaften, Blockierungen, Meldungen und weiteren Anwendungsdaten.\n'
        '• Supabase Storage: Speicherung von Bildern und Medieninhalten.\n'
        '• Firebase Cloud Messaging (Google): Versand von Push-Benachrichtigungen.\n'
        '• Telekom OC: Hosting bzw. Betrieb der Backend-Infrastruktur. Der Serverstandort befindet sich nach aktuellem Stand in den Niederlanden.\n\n'
        'Eine Weitergabe personenbezogener Daten erfolgt nur, soweit dies für den Betrieb der App erforderlich ist, du eingewilligt hast oder eine gesetzliche Pflicht besteht.',
  ),
  _Section(
    heading: '9. Drittlandübermittlungen',
    body:
        'Bei einzelnen Dienstleistern, insbesondere Firebase Cloud Messaging von Google und Supabase, kann eine Verarbeitung außerhalb der Europäischen Union bzw. des Europäischen Wirtschaftsraums nicht vollständig ausgeschlossen werden. '
        'Soweit Daten in Drittländer übertragen werden, erfolgt dies auf Grundlage geeigneter Garantien, insbesondere EU-Standardvertragsklauseln gemäß Art. 46 DSGVO oder eines Angemessenheitsbeschlusses, sofern anwendbar.',
  ),
  _Section(
    heading: '10. Server-Logs und Sicherheit',
    body:
        'Beim Zugriff auf die App und das Backend können technische Zugriffsdaten verarbeitet werden, insbesondere IP-Adresse, Zeitpunkt des Zugriffs, angeforderte Ressourcen und technische Statusinformationen. '
        'Diese Daten dienen der Sicherheit, Fehleranalyse und Stabilität der App. Passwörter werden nicht im Klartext gespeichert, sondern ausschließlich verschlüsselt bzw. gehasht verarbeitet.',
  ),
  _Section(
    heading: '11. Meldungen, Blockierungen und Moderation',
    body:
        'Nutzer können Beiträge melden und andere Nutzer blockieren. Meldungen werden verarbeitet, um mögliche Verstöße gegen Nutzungsbedingungen, Community-Regeln oder geltendes Recht zu prüfen. '
        'Blockierungen werden gespeichert, damit die Interaktion und Sichtbarkeit zwischen betroffenen Nutzern technisch eingeschränkt werden kann.',
  ),
  _Section(
    heading: '12. Account-Löschung',
    body:
        'Du kannst dein Konto jederzeit direkt in der App löschen. Bei einer Kontolöschung werden sämtliche personenbezogenen Daten und mit deinem Konto verbundenen Inhalte gelöscht, soweit keine gesetzlichen Aufbewahrungspflichten bestehen. '
        'Dazu gehören insbesondere dein Nutzerkonto, Profilbild, Beiträge, Bilder, Kommentare, Reaktionen, Freundschaften, Freundschaftsanfragen, Blockierungen und sonstige mit deinem Konto verknüpfte Daten.',
  ),
  _Section(
    heading: '13. Speicherdauer',
    body:
        'Personenbezogene Daten werden grundsätzlich nur so lange gespeichert, wie sie für die genannten Zwecke erforderlich sind oder gesetzliche Aufbewahrungspflichten bestehen. '
        'Daten deines Benutzerkontos werden bis zur Löschung des Kontos gespeichert. Technische Logs werden nur so lange gespeichert, wie sie für Sicherheit, Fehleranalyse und Betrieb erforderlich sind.',
  ),
  _Section(
    heading: '14. Deine Rechte',
    body:
        'Du hast nach der DSGVO insbesondere folgende Rechte:\n\n'
        '• Auskunft über die zu deiner Person gespeicherten Daten gemäß Art. 15 DSGVO\n'
        '• Berichtigung unrichtiger Daten gemäß Art. 16 DSGVO\n'
        '• Löschung deiner Daten gemäß Art. 17 DSGVO\n'
        '• Einschränkung der Verarbeitung gemäß Art. 18 DSGVO\n'
        '• Datenübertragbarkeit gemäß Art. 20 DSGVO\n'
        '• Widerspruch gegen Verarbeitungen auf Grundlage berechtigter Interessen gemäß Art. 21 DSGVO\n'
        '• Widerruf erteilter Einwilligungen gemäß Art. 7 Abs. 3 DSGVO\n\n'
        'Zur Ausübung deiner Rechte kannst du dich an engl.devmail@gmail.com wenden.',
  ),
  _Section(
    heading: '15. Beschwerderecht',
    body:
        'Du hast das Recht, dich bei einer Datenschutz-Aufsichtsbehörde über die Verarbeitung deiner personenbezogenen Daten zu beschweren. '
        'Du kannst dich insbesondere an die Aufsichtsbehörde deines Wohnorts oder an die für den Verantwortlichen zuständige Aufsichtsbehörde wenden.',
  ),
  _Section(
    heading: '16. Änderungen dieser Datenschutzerklärung',
    body:
        'Diese Datenschutzerklärung kann angepasst werden, wenn sich Funktionen der App, eingesetzte Dienste oder rechtliche Anforderungen ändern. '
        'Die jeweils aktuelle Fassung ist innerhalb der App abrufbar.',
  ),
];

const _kTerms = [
  _Section(
    body:
        'Stand: Juni 2026\n\n'
        'Diese Nutzungsbedingungen regeln die Nutzung der App Zapfen. Mit der Registrierung und Nutzung der App akzeptierst du diese Bedingungen.',
  ),
  _Section(
    heading: '1. Anbieter',
    body:
        'Zapfen wird angeboten von:\n\n'
        'Maximilian Engl\n'
        'Am Tennenbach 26\n'
        '91080 Spardorf\n'
        'Deutschland\n\n'
        'E-Mail: engl.devmail@gmail.com',
  ),
  _Section(
    heading: '2. Mindestalter',
    body:
        'Die Nutzung von Zapfen ist ausschließlich Personen gestattet, die das 18. Lebensjahr vollendet haben. '
        'Mit der Registrierung bestätigst du, mindestens 18 Jahre alt zu sein. Konten minderjähriger Nutzer können ohne vorherige Ankündigung gelöscht werden.',
  ),
  _Section(
    heading: '3. Registrierung und Konto',
    body:
        'Für die Nutzung bestimmter Funktionen ist ein Benutzerkonto erforderlich. Du bist verpflichtet, bei der Registrierung richtige Angaben zu machen und deine Zugangsdaten vertraulich zu behandeln. '
        'Dein Konto ist persönlich und darf nicht an Dritte übertragen werden. Du bist für alle Aktivitäten verantwortlich, die über dein Konto erfolgen.',
  ),
  _Section(
    heading: '4. Zweck der App',
    body:
        'Zapfen ist eine Social-App zum Entdecken, Bewerten und Teilen von Getränken jeder Art. '
        'Die App dient nicht der Förderung von gefährlichem, exzessivem oder unverantwortlichem Alkoholkonsum.',
  ),
  _Section(
    heading: '5. Erlaubte Nutzung',
    body:
        'Du darfst Zapfen nur im Rahmen dieser Nutzungsbedingungen, der Community-Regeln und geltender Gesetze nutzen. '
        'Eine kommerzielle Nutzung, automatisierte Nutzung, massenhafte Datenauslesung, Spam, Bots, Scraping oder sonstiger Missbrauch sind ohne ausdrückliche Genehmigung untersagt.',
  ),
  _Section(
    heading: '6. Nutzerinhalte',
    body:
        'Du kannst in Zapfen eigene Inhalte veröffentlichen, insbesondere Beiträge, Bilder, Kommentare und Reaktionen. '
        'Du bist selbst dafür verantwortlich, dass deine Inhalte rechtmäßig sind und keine Rechte Dritter verletzen. '
        'Du darfst nur Inhalte hochladen, an denen du die erforderlichen Rechte besitzt.',
  ),
  _Section(
    heading: '7. Nutzungsrechte an deinen Inhalten',
    body:
        'Du behältst grundsätzlich alle Rechte an den von dir veröffentlichten Inhalten. '
        'Durch das Hochladen räumst du dem Anbieter ein einfaches, nicht-exklusives, unentgeltliches, räumlich unbeschränktes Nutzungsrecht ein, deine Inhalte innerhalb der App zu speichern, zu verarbeiten, darzustellen und anderen Nutzern zugänglich zu machen. '
        'Dieses Recht endet, wenn du den jeweiligen Inhalt oder dein Konto löschst, soweit keine rechtlichen Gründe eine weitere Speicherung erfordern.',
  ),
  _Section(
    heading: '8. Verbotene Inhalte',
    body:
        'Nicht erlaubt sind insbesondere:\n\n'
        '• rechtswidrige Inhalte\n'
        '• beleidigende, bedrohende, belästigende oder diskriminierende Inhalte\n'
        '• Hassrede, extremistische Inhalte oder Gewaltverherrlichung\n'
        '• sexuell explizite oder stark anstößige Inhalte\n'
        '• Inhalte, die Minderjährige im Zusammenhang mit Alkohol zeigen oder gefährden\n'
        '• Inhalte, die gefährlichen oder exzessiven Alkoholkonsum fördern\n'
        '• Spam, Betrug, Werbung ohne Genehmigung oder irreführende Inhalte\n'
        '• Inhalte, die Urheberrechte, Markenrechte, Persönlichkeitsrechte oder sonstige Rechte Dritter verletzen',
  ),
  _Section(
    heading: '9. Meldungen und Moderation',
    body:
        'Nutzer können Beiträge über die Meldefunktion melden. Gemeldete Inhalte werden geprüft und können bei Verstößen gegen diese Nutzungsbedingungen, die Community-Regeln oder geltendes Recht entfernt werden. '
        'Ein Anspruch auf Entfernung bestimmter Inhalte besteht nicht. Der Anbieter behält sich vor, Inhalte zu entfernen, Funktionen einzuschränken, Konten vorübergehend zu sperren oder dauerhaft zu löschen.',
  ),
  _Section(
    heading: '10. Blockieren von Nutzern',
    body:
        'Nutzer können andere Nutzer blockieren. Nach einer Blockierung können die betroffenen Nutzer die Inhalte des jeweils anderen Nutzers nicht mehr einsehen oder mit diesen interagieren, soweit dies technisch möglich ist. '
        'Die Blockierfunktion dient dem Schutz der Nutzer und der Community.',
  ),
  _Section(
    heading: '11. Account-Löschung',
    body:
        'Du kannst dein Konto jederzeit direkt in der App löschen. Bei der Löschung werden die mit deinem Konto verbundenen personenbezogenen Daten und Inhalte gelöscht, soweit keine gesetzlichen Aufbewahrungspflichten bestehen. '
        'Dazu gehören insbesondere Beiträge, Bilder, Kommentare, Reaktionen, Freundschaften, Blockierungen und weitere kontobezogene Daten.',
  ),
  _Section(
    heading: '12. Verfügbarkeit und Änderungen',
    body:
        'Es besteht kein Anspruch auf eine jederzeitige Verfügbarkeit der App. Die App kann weiterentwickelt, geändert, eingeschränkt oder eingestellt werden. '
        'Funktionen können angepasst werden, wenn dies aus technischen, rechtlichen oder sicherheitsbezogenen Gründen erforderlich ist.',
  ),
  _Section(
    heading: '13. Haftung',
    body:
        'Der Anbieter haftet unbeschränkt bei Vorsatz und grober Fahrlässigkeit sowie bei Verletzung von Leben, Körper oder Gesundheit. '
        'Bei leichter Fahrlässigkeit haftet der Anbieter nur bei Verletzung wesentlicher Vertragspflichten und begrenzt auf den vorhersehbaren, vertragstypischen Schaden. '
        'Für Inhalte von Nutzern übernimmt der Anbieter keine Verantwortung, solange keine Kenntnis von rechtswidrigen Inhalten besteht.',
  ),
  _Section(
    heading: '14. Änderungen der Nutzungsbedingungen',
    body:
        'Diese Nutzungsbedingungen können angepasst werden, wenn dies aufgrund neuer Funktionen, rechtlicher Änderungen oder Sicherheitsanforderungen erforderlich ist. '
        'Über wesentliche Änderungen wirst du in geeigneter Weise informiert.',
  ),
  _Section(
    heading: '15. Anwendbares Recht',
    body:
        'Es gilt das Recht der Bundesrepublik Deutschland unter Ausschluss des UN-Kaufrechts. Gesetzliche Verbraucherschutzvorschriften bleiben unberührt.',
  ),
];

const _kCommunityRules = [
  _Section(
    body:
        'Stand: Juni 2026\n\n'
        'Zapfen ist eine Community zum Entdecken und Bewerten von Getränken jeder Art. '
        'Damit die App für alle sicher und angenehm bleibt, gelten diese Community-Regeln.',
  ),
  _Section(
    heading: '1. Mindestalter',
    body:
        'Zapfen ist ausschließlich für Personen ab 18 Jahren bestimmt. Konten minderjähriger Nutzer sind nicht erlaubt und können gelöscht werden.',
  ),
  _Section(
    heading: '2. Respektvoller Umgang',
    body:
        'Behandle andere Nutzer respektvoll. Beleidigungen, Belästigungen, Drohungen, Mobbing oder gezielte Provokationen sind nicht erlaubt.',
  ),
  _Section(
    heading: '3. Kein Hass und keine Diskriminierung',
    body:
        'Inhalte, die Personen oder Gruppen aufgrund von Herkunft, Nationalität, Religion, Geschlecht, sexueller Orientierung, Behinderung, Alter oder anderer Merkmale herabwürdigen oder angreifen, sind verboten.',
  ),
  _Section(
    heading: '4. Verantwortungsbewusster Umgang',
    body:
        'Zapfen dient dem Entdecken und Bewerten von Getränken. Inhalte, die gefährlichen, exzessiven oder verantwortungslosen Alkoholkonsum fördern, verherrlichen oder andere zum Trinken drängen, sind nicht erlaubt.',
  ),
  _Section(
    heading: '5. Schutz Minderjähriger',
    body:
        'Inhalte, die Minderjährige im Zusammenhang mit Alkohol zeigen, ansprechen oder gefährden, sind nicht erlaubt. Dies gilt insbesondere für Bilder, Kommentare oder Beiträge, die Minderjährige beim Konsum oder in einem alkoholbezogenen Kontext darstellen.',
  ),
  _Section(
    heading: '6. Keine illegalen Inhalte',
    body:
        'Veröffentliche keine Inhalte, die gegen geltendes Recht verstoßen. Dazu gehören insbesondere Gewaltverherrlichung, Volksverhetzung, illegale Substanzen, Betrug, Drohungen oder rechtswidrige Aufforderungen.',
  ),
  _Section(
    heading: '7. Keine unangemessenen Bilder',
    body:
        'Sexuell explizite, stark anstößige, gewaltvolle oder entwürdigende Bilder sind nicht erlaubt. Beiträge sollen thematisch zur Community passen.',
  ),
  _Section(
    heading: '8. Rechte Dritter beachten',
    body:
        'Lade nur Inhalte hoch, an denen du die nötigen Rechte besitzt. Achte insbesondere auf Urheberrechte, Markenrechte und Persönlichkeitsrechte anderer Personen.',
  ),
  _Section(
    heading: '9. Keine Täuschung',
    body:
        'Gib dich nicht als eine andere Person, Marke oder Organisation aus. Fake-Accounts, betrügerische Inhalte und absichtliche Irreführung sind nicht erlaubt.',
  ),
  _Section(
    heading: '10. Kein Spam',
    body:
        'Spam, massenhafte Freundschaftsanfragen, automatisierte Aktionen, Werbung ohne Genehmigung und störendes Verhalten sind nicht erlaubt.',
  ),
  _Section(
    heading: '11. Melden und Blockieren',
    body:
        'Wenn du Inhalte siehst, die gegen diese Regeln verstoßen, kannst du sie direkt in der App melden. Du kannst außerdem Nutzer blockieren, mit denen du nicht interagieren möchtest.',
  ),
  _Section(
    heading: '12. Folgen bei Verstößen',
    body:
        'Bei Verstößen gegen diese Regeln können Inhalte entfernt, Funktionen eingeschränkt, Nutzerkonten gesperrt oder dauerhaft gelöscht werden.',
  ),
];
