import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../entities/plan.dart';
import '../services/api_service.dart';
import '../services/purchase_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Package> _rcPackages = [];
  List<Plan> _apiPlans = [];
  bool _isSubmitting = false;
  String _billingCycle = 'monthly'; // 'monthly' ou 'yearly'

  final ApiService _apiService = ApiService();
  final SessionManager _sessionManager = SessionManager();

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  // Obtém as ofertas do RevenueCat e os planos do backend simultaneamente
  Future<void> _loadOfferings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Busca os planos da API interna
      final apiPlans = await _apiService.fetchActivePlans();
      
      // Ordena por preço crescente
      apiPlans.sort((a, b) => a.price.compareTo(b.price));

      // 2. Busca as ofertas do RevenueCat
      final offerings = await PurchaseService.fetchOfferings();
      final currentOffering = offerings.current;

      if (currentOffering != null && currentOffering.availablePackages.isNotEmpty) {
        setState(() {
          _apiPlans = apiPlans;
          _rcPackages = currentOffering.availablePackages;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = context.l10n('plan_error');
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = context.l10n('plan_error');
        _isLoading = false;
      });
    }
  }

  // Executa o processo de compra do pacote selecionado no RevenueCat
  Future<void> _purchasePackage(Package package) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      await Purchases.purchase(PurchaseParams.package(package));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n('success')),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context, true); // Retorna true indicando sucesso
      }
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${context.l10n('error')}: ${e.message}"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${context.l10n('error')}: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Efetua downgrade/troca de plano diretamente pela API (ex: voltar ao plano gratuito)
  Future<void> _changePlanApi(String planPackage) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      await _apiService.changePlan(planPackage);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n('success')),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n('network_error')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Confirmação para planos pagos no RevenueCat
  Future<void> _confirmPurchase(Package package, String planName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_bag,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                planName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n('Plans_Modal_Desc', args: [planName]),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                package.storeProduct.priceString,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n('Plans_Modal_Notice'),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                          side: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Text(
                        context.l10n('Plans_Modal_Cancel'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textLight,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(context.l10n('Plans_Modal_Confirm')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      _purchasePackage(package);
    }
  }

  // Confirmação para alteração direta via API (plano gratuito)
  Future<void> _confirmChangePlanApi(Plan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_bag,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                plan.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n('Plans_Modal_Desc', args: [plan.name]),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n('Plans_Modal_Notice'),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                          side: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Text(
                        context.l10n('Plans_Modal_Cancel'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textLight,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(context.l10n('Plans_Modal_Confirm')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      _changePlanApi(plan.package);
    }
  }

  Future<void> _contactSupport() async {
    final Uri url = Uri.parse('mailto:support@nanourls.com?subject=NanoUrls%20Support');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        _showSupportClipboardSnackBar();
      }
    } catch (_) {
      _showSupportClipboardSnackBar();
    }
  }

  void _showSupportClipboardSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${context.l10n('Plans_Footer_Support')}: support@nanourls.com"),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n('Plans_Title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMessage != null
                    ? _buildErrorWidget()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              context.l10n('Plans_Header_Title'),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Text(
                                context.l10n('Plans_Header_Desc'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textMuted,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),

                            _buildBillingToggle(),

                            const SizedBox(height: 16),

                            // Loop sob os planos da API que não são anuais para agrupamento
                            ..._apiPlans.where((p) => !p.isAnnual).map((plan) {
                              // Localiza o package mensal correspondente
                              Package? monthlyPkg;
                              for (var pkg in _rcPackages) {
                                if (pkg.identifier == plan.package) {
                                  monthlyPkg = pkg;
                                  break;
                                }
                              }

                              // Localiza o package anual correspondente
                              Package? yearlyPkg;
                              final yearlyPackageName = plan.package.replaceAll('_monthly', '_annual');
                              for (var pkg in _rcPackages) {
                                if (pkg.identifier == yearlyPackageName) {
                                  yearlyPkg = pkg;
                                  break;
                                }
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: _buildPlanCard(plan, monthlyPkg, yearlyPkg),
                              );
                            }),

                            Center(child: _buildFooterSupport()),
                          ],
                        ),
                      ),
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _billingCycle = 'monthly'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  color: _billingCycle == 'monthly'
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  border: _billingCycle == 'monthly'
                      ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
                      : null,
                ),
                child: Center(
                  child: Text(
                    context.l10n('Plans_Toggle_Monthly'),
                    style: TextStyle(
                      color: _billingCycle == 'monthly' ? AppColors.primary : AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _billingCycle = 'yearly'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  color: _billingCycle == 'yearly'
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  border: _billingCycle == 'yearly'
                      ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.l10n('Plans_Toggle_Yearly'),
                      style: TextStyle(
                        color: _billingCycle == 'yearly' ? AppColors.primary : AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        '-20%',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? context.l10n('plan_error'),
              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadOfferings,
              child: Text(context.l10n('try_again')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(Plan plan, Package? monthlyPkg, Package? yearlyPkg) {
    final isYearlySelected = _billingCycle == 'yearly';
    final activePkg = isYearlySelected ? yearlyPkg : monthlyPkg;

    // Preço formatado (prioriza o do RevenueCat, senão usa R$0.00)
    final priceStr = activePkg?.storeProduct.priceString ?? "\$0.00";

    // Busca o plano correspondente ao yearlyPkg
    Plan? yearlyPlan;
    if (yearlyPkg != null) {
      for (var p in _apiPlans) {
        if (p.package == yearlyPkg.identifier) {
          yearlyPlan = p;
          break;
        }
      }
    }

    // Valida se este plano representa a assinatura ativa do usuário
    final user = _sessionManager.currentUser;
    final isCurrentPlan = user != null && 
        (user.planId == plan.planId || (yearlyPlan != null && user.planId == yearlyPlan.planId));

    // Determina o texto do botão
    String btnText = context.l10n('Plans_Btn_SubscribePro');
    if (isCurrentPlan) {
      btnText = context.l10n('Plans_Btn_Current');
    } else if (plan.package == 'free') {
      btnText = context.l10n('Plans_Btn_StartFree');
    } else if (plan.package == 'max_monthly') {
      btnText = context.l10n('Plans_Btn_BeMax');
    }

    // Tradução das features utilizando as chaves localizadas
    final linksStr = plan.linksPerMonth == -1 
        ? context.l10n('Plans_Feat_Links_Unlimited') 
        : context.l10n('Plans_Feat_Links_Format', args: [plan.linksPerMonth]);
    
    final analyticsStr = plan.maxAnalytics == -1 
        ? context.l10n('Plans_Feat_Analytics_Unlimited') 
        : context.l10n('Plans_Feat_Analytics_Format', args: [plan.maxAnalytics]);

    // Descrição localizada do plano
    String planDesc = '';
    if (plan.package == 'free') {
      planDesc = context.l10n('Plans_Desc_1');
    } else if (plan.package == 'pro_monthly') {
      planDesc = context.l10n('Plans_Desc_2');
    } else {
      planDesc = context.l10n('Plans_Desc_3');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrentPlan ? AppColors.primary : Colors.white.withValues(alpha: 0.1),
          width: isCurrentPlan ? 2.0 : 1.0,
        ),
        boxShadow: isCurrentPlan
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      context.l10n('Plans_Badge_Current'),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              planDesc,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  priceStr,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isYearlySelected ? context.l10n('Plans_Per_Year') : context.l10n('Plans_Per_Month'),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 28),
            
            // Lista de Features Positivas (apenas se verdadeiro na entidade)
            _buildFeatureRow(linksStr),
            _buildFeatureRow(analyticsStr),
            if (plan.hasDetailedAnalytics) _buildFeatureRow(context.l10n('Plans_Feat_DetailedAnalytics')),
            if (!plan.showAds) _buildFeatureRow(context.l10n('Plans_Feat_NoAds')),
            if (plan.fullWebAccess) _buildFeatureRow(context.l10n('Plans_Feat_FullWebAccess')),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isCurrentPlan
                    ? null
                    : () {
                        if (plan.package == 'free') {
                          _confirmChangePlanApi(plan);
                        } else if (activePkg != null) {
                          _confirmPurchase(activePkg, plan.name);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrentPlan ? Colors.white10 : AppColors.primary,
                  foregroundColor: isCurrentPlan ? Colors.white30 : AppColors.textLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: isCurrentPlan ? 0 : 4,
                ),
                child: Text(btnText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSupport() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Text(
          context.l10n('Plans_Footer_Questions'),
          style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _contactSupport,
          child: Text(
            context.l10n('Plans_Footer_Support'),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
