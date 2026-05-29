import 'package:flutter/material.dart';

class GlyphHelper {
  static const List<String> availableGlyphs = [
    "link", "star", "favorite", "home", "work",
    "shopping_cart", "rocket_launch", "bolt", "mail", "person",
    "verified", "lock", "schedule", "group", "photo_camera",
    "music_note", "flight", "restaurant", "school", "code",
    "search", "settings", "notifications", "share", "delete",
    "edit", "check_circle", "warning", "info", "help"
  ];

  static IconData getIconData(String? name) {
    switch (name?.toLowerCase()) {
      case 'link': return Icons.link;
      case 'star': return Icons.star;
      case 'favorite': return Icons.favorite;
      case 'home': return Icons.home;
      case 'work': return Icons.work;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'rocket_launch': return Icons.rocket_launch;
      case 'bolt': return Icons.bolt;
      case 'mail': return Icons.mail;
      case 'person': return Icons.person;
      case 'verified': return Icons.verified;
      case 'lock': return Icons.lock;
      case 'schedule': return Icons.schedule;
      case 'group': return Icons.group;
      case 'photo_camera': return Icons.photo_camera;
      case 'music_note': return Icons.music_note;
      case 'flight': return Icons.flight;
      case 'restaurant': return Icons.restaurant;
      case 'school': return Icons.school;
      case 'code': return Icons.code;
      case 'search': return Icons.search;
      case 'settings': return Icons.settings;
      case 'notifications': return Icons.notifications;
      case 'share': return Icons.share;
      case 'delete': return Icons.delete;
      case 'edit': return Icons.edit;
      case 'check_circle': return Icons.check_circle;
      case 'warning': return Icons.warning;
      case 'info': return Icons.info;
      case 'help': return Icons.help;
      default: return Icons.link;
    }
  }
}
