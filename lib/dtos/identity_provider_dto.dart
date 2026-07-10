// Provedor de identidade (SSO social) ativo no Keycloak, devolvido por
// GET /v1/user/identity-providers. Usado para renderizar os botões sociais
// dinamicamente na tela de login, sem hardcodar cada provedor no app.
class IdentityProviderDto {
  final String alias;
  final String displayName;

  IdentityProviderDto({
    required this.alias,
    required this.displayName,
  });

  factory IdentityProviderDto.fromJson(Map<String, dynamic> json) {
    return IdentityProviderDto(
      alias: json['alias'] ?? '',
      displayName: json['displayName'] ?? '',
    );
  }
}
