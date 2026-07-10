import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Escolhe o ícone (Font Awesome Free) exibido no botão de cada provedor social,
// a partir do alias devolvido pelo Keycloak. O alias não é padronizado pelo
// protocolo, então o match é por substring; provedores sem ícone de marca mapeado
// caem num ícone genérico, sem exigir alteração de código para novos aliases
class IdentityProviderIconHelper {
  static FaIconData getFaIconData(String alias) {
    final normalized = alias.toLowerCase();

    if (normalized.contains('google')) return FontAwesomeIcons.google;
    if (normalized.contains('apple')) return FontAwesomeIcons.apple;
    if (normalized.contains('microsoft') || normalized.contains('azure')) return FontAwesomeIcons.microsoft;
    if (normalized.contains('facebook') || normalized.contains('meta')) return FontAwesomeIcons.facebook;
    if (normalized.contains('github')) return FontAwesomeIcons.github;
    if (normalized.contains('gitlab')) return FontAwesomeIcons.gitlab;
    if (normalized.contains('linkedin')) return FontAwesomeIcons.linkedin;
    if (normalized.contains('twitter') || normalized == 'x') return FontAwesomeIcons.xTwitter;
    if (normalized.contains('instagram')) return FontAwesomeIcons.instagram;
    if (normalized.contains('discord')) return FontAwesomeIcons.discord;

    return FontAwesomeIcons.key;
  }
}
