import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_utils.dart';
import '../models/asset_model.dart';
import '../widgets/pin_dialog.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  static Future<void> showPublierListing(BuildContext context, AssetProvider prov, AuthProvider auth, {Asset? preselectedAsset}) async {
    // ─── Verification PIN avant publication
    if (auth.user?.hasPinConfigured == true) {
      final ok = await PinDialog.show(context);
      if (!ok || !context.mounted) return;
    }
    final certifies = prov.assetsCertifies;
    if (certifies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vous devez d\'abord certifier un actif pour le publier'),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }
    Asset? selectedAsset = preselectedAsset ?? certifies.first;
    ListingType type = ListingType.vente;
    final titreC = TextEditingController(text: selectedAsset?.nom ?? certifies.first.nom);
    final descC = TextEditingController();
    final prixC = TextEditingController();
    final localisationC = TextEditingController();
    final conditionsC = TextEditingController();
    final cautionC = TextEditingController(text: '0');
    final avanceC = TextEditingController(text: '0');
    final dureeC = TextEditingController(text: '12');
    final renouvC = TextEditingController(text: '-1');
    final devise = auth.user?.devise ?? 'XOF';
    bool prixNegociable = false;
    DateTime dateMiseEnVente = DateTime.now();

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.navyMedium,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx2).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.storefront_rounded, color: AppTheme.gold, size: 20),
                const SizedBox(width: 8),
                const Text('Publier sur la Marketplace', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 16),
              const Text('ACTIF CERTIFIÉ', style: TextStyle(color: AppTheme.gold, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<Asset>(
                value: selectedAsset,
                dropdownColor: AppTheme.navyMedium,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.verified_rounded, color: AppTheme.success, size: 20)),
                items: certifies.map((a) => DropdownMenuItem(value: a, child: Text(a.nom, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (a) { setS(() { selectedAsset = a; if (a != null) titreC.text = a.nom; }); },
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _typeBtn('Vente', ListingType.vente, type, (t) => setS(() => type = t), AppTheme.colorInvestissement)),
                const SizedBox(width: 10),
                Expanded(child: _typeBtn('Location', ListingType.location, type, (t) => setS(() => type = t), AppTheme.colorImmobilier)),
              ]),
              const SizedBox(height: 14),
              const Text('ANNONCE', style: TextStyle(color: AppTheme.gold, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _tf4(titreC, 'Titre de l\'annonce', Icons.title_rounded),
              const SizedBox(height: 10),
              _tf4(descC, 'Description (optionnel)', Icons.notes_rounded),
              const SizedBox(height: 10),
              _tf4(prixC, type == ListingType.location ? 'Loyer mensuel ($devise)' : 'Prix de vente ($devise)', Icons.payments_rounded, type: TextInputType.number),
              const SizedBox(height: 10),
              _tf4(localisationC, 'Localisation', Icons.location_on_rounded),

              // ─── Champs VENTE
              if (type == ListingType.vente) ...[
                const SizedBox(height: 14),
                const Text('DÉTAILS VENTE', style: TextStyle(color: AppTheme.colorInvestissement, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx2,
                      initialDate: dateMiseEnVente,
                      firstDate: DateTime(2000), lastDate: DateTime(2100),
                      builder: (c, child) => Theme(data: Theme.of(c).copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.gold, surface: AppTheme.navyMedium)), child: child!),
                    );
                    if (d != null) setS(() => dateMiseEnVente = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.navyLight)),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_rounded, color: AppTheme.gold, size: 18),
                      const SizedBox(width: 10),
                      Text('Date de mise en vente : ${AppUtils.formatDate(dateMiseEnVente)}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                    ]),
                  ),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Checkbox(value: prixNegociable, onChanged: (v) => setS(() => prixNegociable = v ?? false), activeColor: AppTheme.gold),
                  const Text('Prix négociable', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                ]),
                _tf4(conditionsC, 'Conditions particulières (optionnel)', Icons.gavel_rounded),
              ],

              // ─── Champs LOCATION
              if (type == ListingType.location) ...[
                const SizedBox(height: 14),
                const Text('DÉTAILS LOCATION', style: TextStyle(color: AppTheme.colorImmobilier, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _tf4(dureeC, 'Durée (mois, 0=illimité)', Icons.schedule_rounded, type: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _tf4(renouvC, 'Renouvellements (-1=∞)', Icons.autorenew_rounded, type: TextInputType.number)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _tf4(cautionC, 'Caution ($devise)', Icons.security_rounded, type: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _tf4(avanceC, 'Avance ($devise)', Icons.payments_outlined, type: TextInputType.number)),
                ]),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (selectedAsset == null || prixC.text.isEmpty) return;
                    await prov.publierListing(MarketplaceListing(
                      id: prov.generateId(),
                      assetId: selectedAsset!.id,
                      proprietaireId: auth.user?.id ?? '',
                      proprietaireNom: auth.user?.nomComplet ?? '',
                      proprietaireTel: auth.user?.telephone ?? '',
                      type: type,
                      prix: double.tryParse(prixC.text.replaceAll(',', '.')) ?? 0,
                      devise: devise,
                      titre: titreC.text.trim(),
                      description: descC.text.trim(),
                      pays: auth.user?.pays ?? 'Burkina Faso',
                      localisation: localisationC.text.trim(),
                      datePublication: DateTime.now(),
                      dateMiseEnVente: type == ListingType.vente ? dateMiseEnVente : null,
                      prixNegociable: type == ListingType.vente ? prixNegociable : false,
                      conditionsVente: type == ListingType.vente ? conditionsC.text.trim() : '',
                      dureeMois: type == ListingType.location ? (int.tryParse(dureeC.text) ?? 12) : 0,
                      nbRenouvellements: type == ListingType.location ? (int.tryParse(renouvC.text) ?? -1) : 0,
                      montantCaution: type == ListingType.location ? (double.tryParse(cautionC.text.replaceAll(',', '.')) ?? 0) : 0,
                      montantAvance: type == ListingType.location ? (double.tryParse(avanceC.text.replaceAll(',', '.')) ?? 0) : 0,
                    ));
                    if (ctx2.mounted) Navigator.pop(ctx2);
                  },
                  icon: const Icon(Icons.publish_rounded, size: 18),
                  label: const Text('Publier l\'annonce', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  static Widget _typeBtn(String label, ListingType val, ListingType current, ValueChanged<ListingType> onTap, Color color) {
    final sel = current == val;
    return GestureDetector(
      onTap: () => onTap(val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: sel ? color.withValues(alpha: 0.2) : AppTheme.navyCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? color : AppTheme.navyLight, width: sel ? 2 : 1),
        ),
        child: Center(child: Text(label, style: TextStyle(color: sel ? color : AppTheme.textMuted, fontWeight: FontWeight.w600))),
      ),
    );
  }

  static Widget _tf4(TextEditingController c, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: c, keyboardType: type,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppTheme.gold, size: 20)),
    );
  }

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _filterType = 'tous';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      body: Consumer2<AssetProvider, AuthProvider>(
        builder: (context, prov, auth, _) {
          return SafeArea(
            child: Column(
            children: [
              _buildHeader(context, prov, auth),
              Container(
                color: AppTheme.navyMedium,
                child: TabBar(
                  controller: _tab,
                  indicatorColor: AppTheme.gold,
                  labelColor: AppTheme.gold,
                  unselectedLabelColor: AppTheme.textMuted,
                  tabs: const [
                    Tab(icon: Icon(Icons.storefront_rounded, size: 18), child: Text('Marketplace', style: TextStyle(fontSize: 12))),
                    Tab(icon: Icon(Icons.inventory_2_rounded, size: 18), child: Text('Mes annonces', style: TextStyle(fontSize: 12))),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _buildMarketplace(context, prov, auth),
                    _buildMesAnnonces(context, prov, auth),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
    );
  }

  Widget _buildHeader(BuildContext context, AssetProvider prov, AuthProvider auth) {
    final actifs = prov.listingsActifs;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 20, 12),
      color: AppTheme.navyMedium,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Marketplace', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              Text('${actifs.length} annonce${actifs.length > 1 ? 's' : ''} active${actifs.length > 1 ? 's' : ''}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ]),
          ),
          ElevatedButton.icon(
            onPressed: () => MarketplaceScreen.showPublierListing(context, prov, auth),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Publier'),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketplace(BuildContext context, AssetProvider prov, AuthProvider auth) {
    var listings = prov.listingsActifs;
    if (_filterType == 'vente') listings = listings.where((l) => l.type == ListingType.vente).toList();
    if (_filterType == 'location') listings = listings.where((l) => l.type == ListingType.location).toList();

    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: listings.isEmpty
              ? _buildEmptyMarket()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: listings.length,
                  itemBuilder: (_, i) => _buildListingCard(context, listings[i], prov, auth, isOwner: false),
                ),
        ),
      ],
    );
  }

  Widget _buildMesAnnonces(BuildContext context, AssetProvider prov, AuthProvider auth) {
    final userId = auth.user?.id ?? '';
    final mesListings = prov.listings.where((l) => l.proprietaireId == userId).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.lock_rounded, color: AppTheme.gold, size: 16),
              const SizedBox(width: 8),
              const Expanded(child: Text('Seuls les actifs certifiés peuvent être publiés sur la marketplace.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
            ]),
          ),
        ),
        Expanded(
          child: mesListings.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.inventory_2_outlined, color: AppTheme.textMuted, size: 52),
                  const SizedBox(height: 14),
                  const Text('Aucune annonce publiée', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => MarketplaceScreen.showPublierListing(context, prov, auth),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Publier un actif'),
                  ),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: mesListings.length,
                  itemBuilder: (_, i) => _buildListingCard(context, mesListings[i], prov, auth, isOwner: true),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.navyDark,
      child: Row(children: [
        _filterChip('tous', 'Tout'),
        const SizedBox(width: 8),
        _filterChip('vente', 'À vendre'),
        const SizedBox(width: 8),
        _filterChip('location', 'À louer'),
      ]),
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _filterType == value;
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.gold.withValues(alpha: 0.2) : AppTheme.navyCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.gold : AppTheme.navyLight),
        ),
        child: Text(label, style: TextStyle(color: selected ? AppTheme.gold : AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildListingCard(BuildContext context, MarketplaceListing l, AssetProvider prov, AuthProvider auth, {required bool isOwner}) {
    final isVente = l.type == ListingType.vente;
    final color = isVente ? AppTheme.colorInvestissement : AppTheme.colorImmobilier;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withValues(alpha: 0.15), AppTheme.navyCard], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(isVente ? Icons.sell_rounded : Icons.vpn_key_rounded, color: Colors.white, size: 12),
                const SizedBox(width: 4),
                Text(isVente ? 'VENTE' : 'LOCATION', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.verified_rounded, color: AppTheme.success, size: 12),
                const SizedBox(width: 4),
                const Text('CERTIFIÉ', style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold)),
              ]),
            ),
            const Spacer(),
            if (isOwner)
              GestureDetector(
                onTap: () => prov.retirerListing(l.id),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.close_rounded, color: AppTheme.danger, size: 18),
                ),
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.titre, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on_rounded, color: AppTheme.textMuted, size: 14),
              const SizedBox(width: 4),
              Text('${l.localisation} · ${l.pays}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ]),
            if (l.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                '${AppUtils.formatMontant(l.prix, devise: l.devise)}${isVente ? '' : '/mois'}',
                style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (!isOwner)
                ElevatedButton.icon(
                  onPressed: () => _showContactProprietaire(context, l),
                  icon: const Icon(Icons.contact_phone_rounded, size: 16),
                  label: const Text('Contacter', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.visibility_rounded, color: AppTheme.textMuted, size: 12),
              const SizedBox(width: 4),
              Text('${l.vues} vue${l.vues > 1 ? 's' : ''} · Publié le ${AppUtils.formatDate(l.datePublication)}',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildEmptyMarket() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.storefront_outlined, color: AppTheme.textMuted, size: 60),
      const SizedBox(height: 16),
      const Text('Aucun actif disponible', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
      const SizedBox(height: 8),
      const Text('Les actifs certifiés mis en vente\nou en location apparaîtront ici.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13), textAlign: TextAlign.center),
    ]));
  }

  Future<void> _showContactProprietaire(BuildContext context, MarketplaceListing l) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.navyMedium,
        title: Row(children: [
          const Icon(Icons.verified_rounded, color: AppTheme.success, size: 20),
          const SizedBox(width: 8),
          const Text('Propriétaire certifié', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Ces informations sont partagées car l\'actif est certifié :', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 14),
          _contactRow(Icons.person_rounded, 'Propriétaire', l.proprietaireNom),
          const SizedBox(height: 10),
          _contactRow(Icons.phone_rounded, 'Téléphone', l.proprietaireTel),
          const SizedBox(height: 10),
          _contactRow(Icons.location_on_rounded, 'Localisation', '${l.localisation}, ${l.pays}'),
          const SizedBox(height: 10),
          _contactRow(Icons.sell_rounded, 'Prix', '${AppUtils.formatMontant(l.prix, devise: l.devise)}${l.type == ListingType.location ? '/mois' : ''}'),
        ]),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, color: AppTheme.gold, size: 16),
      const SizedBox(width: 8),
      Text('$label : ', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
      Expanded(child: Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
    ]);
  }
}
