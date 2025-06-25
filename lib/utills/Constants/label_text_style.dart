import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';



TextStyle get textSplash => GoogleFonts.modak(
    fontWeight: FontWeight.w400, fontSize: 24, color: AppColors.black);

TextStyle get text16w500White => GoogleFonts.inter(
      color: Colors.white,
      fontWeight: FontWeight.w500,
      fontSize: 16.0,
    );
TextStyle get textStyleRoboto => GoogleFonts.getFont(
      'Roboto',
      color: AppColors.colorWhite,
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.italic,
      fontSize: 14.0,
    );

TextStyle get text16w500black => GoogleFonts.mulish(
      color: Colors.black,
      fontWeight: FontWeight.w500,
      fontSize: 16.0,
    );
TextStyle get text14w500Color2 => GoogleFonts.poppins(
      color: Colors.white,
      fontWeight: FontWeight.w500,
      fontSize: 14.0,
    );
TextStyle get text16w500Black => GoogleFonts.poppins(
      color: Colors.black,
      fontWeight: FontWeight.w500,
      fontSize: 16.0,
    );
TextStyle get text18Black => const TextStyle(
      fontFamily: 'Montserrat', // Change as needed
      color: Colors.black,
      fontWeight: FontWeight.w700,
      fontSize: 18.0,
    );
TextStyle get text14w500ColorGray => GoogleFonts.poppins(
      color: Colors.black,
      fontWeight: FontWeight.w500,
      fontSize: 14.0,
    );


TextStyle get text14W500Red => GoogleFonts.getFont(
      'Inter',
      color: Colors.red,
      fontWeight: FontWeight.w500,
      fontSize: 14.0,
    );

TextStyle  text14W400White(BuildContext context) => GoogleFonts.manrope(
      color: Colors.white,
      fontSize: MediaQuery.of(context).size.width * 0.035,
      fontWeight: FontWeight.w400,
    );
    TextStyle  text15W400White(BuildContext context) => GoogleFonts.manrope(
      color: Colors.white,
      fontSize: MediaQuery.of(context).size.width * 0.037,
      fontWeight: FontWeight.w400,
    );

    TextStyle  text16W700White(BuildContext context) => GoogleFonts.manrope(
      color: Colors.white,
      fontSize: MediaQuery.of(context).size.width * 0.04,
      fontWeight: FontWeight.w700,
    );

     TextStyle  text16W400White(BuildContext context) => GoogleFonts.manrope(
      color: Colors.white,
      fontSize: MediaQuery.of(context).size.width * 0.04,
      fontWeight: FontWeight.w400,
    );

    TextStyle  text14W500White(BuildContext context) => GoogleFonts.manrope(
      color: Colors.white,
      fontSize: MediaQuery.of(context).size.width * 0.035,
      fontWeight: FontWeight.w500,
    );

    TextStyle  text18W700White(BuildContext context) => GoogleFonts.nunitoSans(
      color: Colors.white,
      fontSize: MediaQuery.of(context).size.width * 0.045,
      fontWeight: FontWeight.w700,
    );

    TextStyle  text20W800White(BuildContext context) => GoogleFonts.manrope(
      color: Colors.white,
      fontSize: MediaQuery.of(context).size.width * 0.05,
      fontWeight: FontWeight.w800,
    );

    TextStyle  text14W800Yellow(BuildContext context) => GoogleFonts.nunitoSans(
      color: Color(0xFFEBA145),
      fontSize: MediaQuery.of(context).size.width * 0.035,
      fontWeight: FontWeight.w800,
    );

    TextStyle  text12W700Yellow(BuildContext context) => GoogleFonts.nunitoSans(
      color: Color(0xFFF5BF4D),
      fontSize: MediaQuery.of(context).size.width * 0.030,
      fontWeight: FontWeight.w700,
    );

    TextStyle  text12W400White(BuildContext context) => GoogleFonts.nunitoSans(
      color:Colors.white,
      fontSize: MediaQuery.of(context).size.width * 0.030,
      fontWeight: FontWeight.w400,
    );

    TextStyle  text14W600White(BuildContext context) => GoogleFonts.nunitoSans(
      color: Colors.white,
      fontSize: MediaQuery.of(context).size.width * 0.035,
      fontWeight: FontWeight.w700,
    );

    TextStyle  text16W600White(BuildContext context) => GoogleFonts.nunitoSans(
      color: Colors.white,
      fontSize: MediaQuery.of(context).size.width * 0.04,
      fontWeight: FontWeight.w600,
    );
TextStyle get text14w500 => GoogleFonts.poppins(
      color: Colors.red,
      fontWeight: FontWeight.w500,
      fontSize: 14.0,
    );
TextStyle get text14w600 => GoogleFonts.poppins(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 14.0,
    );
TextStyle get textPoppins16w600 => GoogleFonts.poppins(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 16.0,
    );

// Kanit font styles
TextStyle get textKanit20w600 => GoogleFonts.kanit(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.0, // for 100% line height
      letterSpacing: 0,
      color: Colors.white,
    );

TextStyle get textKanit14w400 => GoogleFonts.kanit(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.0,
      letterSpacing: 0,
      color: Colors.white,
    );

TextStyle get textKanit12w400 => GoogleFonts.kanit(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.0,
      letterSpacing: 0,
      color: Colors.white,
    );
TextStyle get textKanit16w500 => GoogleFonts.kanit(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.0,
      letterSpacing: 0,
      color: Colors.white,
    );

    
