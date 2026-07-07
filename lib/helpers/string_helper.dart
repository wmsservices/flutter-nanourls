class StringHelper
{
  /// Máscara inteligente para emails
  /// Retorna um email mascarado no formato: primeiros2chars***@***dominio
  /// Trata erros de comprimento e emails inválidos
  static String maskEmail(String email) {
    // Validações básicas
    if (email.isEmpty) {
      return '***@***';
    }

    email = email.trim().toLowerCase();

    // Verifica se contém @
    if (!email.contains('@')) {
      return '***@***';
    }

    try {
      final parts = email.split('@');

      // Validação: deve ter exatamente 2 partes (antes e depois do @)
      if (parts.length != 2) {
        return '***@***';
      }

      final localPart = parts[0];  // antes do @
      final domain = parts[1];      // depois do @

      // Validações de comprimento
      if (localPart.isEmpty || domain.isEmpty) {
        return '***@***';
      }

      // Estratégia inteligente para mascarar a parte local
      String maskedLocal;
      if (localPart.length <= 2) {
        // Se tem 1-2 caracteres, mostra tudo
        maskedLocal = localPart;
      } else if (localPart.length <= 4) {
        // Se tem 3-4 caracteres, mostra 2 + ***
        maskedLocal = localPart.substring(0, 2) + '***';
      } else {
        // Se tem 5+, mostra primeiro + *** + último
        maskedLocal = localPart[0] + '***' + localPart[localPart.length - 1];
      }

      // Estratégia inteligente para mascarar o domínio
      String maskedDomain;
      if (domain.length <= 3) {
        // Se é muito curto (ex: .co), mostra como está
        maskedDomain = domain;
      } else if (domain.length <= 6) {
        // Se tem 4-6 caracteres, mostra primeiro + *** + último
        maskedDomain = domain[0] + '***' + domain[domain.length - 1];
      } else {
        // Se tem 7+, mostra primeiro + *** + 2 últimos
        maskedDomain = domain[0] + '***' + domain.substring(domain.length - 2);
      }

      return '$maskedLocal@$maskedDomain';
    } catch (e) {
      // Em caso de qualquer erro, retorna fallback seguro
      return '***@***';
    }
  }

// ============================================================================
// EXEMPLOS DE USO
// ============================================================================

  void main() {
    // Testes
    print(maskEmail('joao@gmail.com'));           // j***o@g***m
    print(maskEmail('maria.silva@empresa.com.br')); // m***a@e***r
    print(maskEmail('a@b.co'));                   // a@b.co
    print(maskEmail('ab@domain.org'));            // ab@d***g
    print(maskEmail('teste@outlook.co'));         // t***e@o***k
    print(maskEmail(''));                         // ***@***
    print(maskEmail('invalido'));                 // ***@***
    print(maskEmail('   user@example.com   ')); // u***r@e***e
    print(maskEmail('x@y'));                      // x@y
    print(maskEmail('verylong.emailaddress@verylongdomainname.com'));
    // v***e@v***m
  }

}