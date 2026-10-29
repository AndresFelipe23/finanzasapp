import 'package:flutter/material.dart';
import '../../core/theme/brand.dart';

/// Ícono, colores y nombre legible de cada tipo de cuenta (`cuentas.tipo`).
({IconData icon, Color fg, Color bg, String label}) accountStyle(String tipo) =>
    switch (tipo) {
      'EFECTIVO' => (
        icon: Icons.payments_outlined,
        fg: Brand.accent,
        bg: Brand.accentSoft,
        label: 'Efectivo',
      ),
      'TARJETA_DEBITO' => (
        icon: Icons.credit_card_outlined,
        fg: Brand.blue,
        bg: Brand.blueSoft,
        label: 'Tarjeta de débito',
      ),
      'TARJETA_CREDITO' => (
        icon: Icons.credit_card_outlined,
        fg: Brand.expense,
        bg: Brand.expenseSoft,
        label: 'Tarjeta de crédito',
      ),
      'DIGITAL' => (
        icon: Icons.phone_iphone_rounded,
        fg: Brand.blue,
        bg: Brand.blueSoft,
        label: 'Billetera digital',
      ),
      'AHORRO' => (
        icon: Icons.savings_outlined,
        fg: Brand.accent,
        bg: Brand.accentSoft,
        label: 'Ahorro',
      ),
      'INVERSION' => (
        icon: Icons.trending_up_rounded,
        fg: Color(0xFF6B3FA0),
        bg: Color(0xFFEEE8F5),
        label: 'Inversión',
      ),
      _ => (
        icon: Icons.account_balance_outlined,
        fg: Brand.accent,
        bg: Brand.accentSoft,
        label: 'Cuenta bancaria',
      ),
    };
