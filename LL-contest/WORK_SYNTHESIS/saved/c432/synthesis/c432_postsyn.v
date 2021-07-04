/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Expert(TM) in wire load mode
// Version   : O-2018.06-SP4
// Date      : Sun Jul  4 11:18:07 2021
/////////////////////////////////////////////////////////////


module c432 ( N1, N4, N8, N11, N14, N17, N21, N24, N27, N30, N34, N37, N40, 
        N43, N47, N50, N53, N56, N60, N63, N66, N69, N73, N76, N79, N82, N86, 
        N89, N92, N95, N99, N102, N105, N108, N112, N115, N223, N329, N370, 
        N421, N430, N431, N432 );
  input N1, N4, N8, N11, N14, N17, N21, N24, N27, N30, N34, N37, N40, N43, N47,
         N50, N53, N56, N60, N63, N66, N69, N73, N76, N79, N82, N86, N89, N92,
         N95, N99, N102, N105, N108, N112, N115;
  output N223, N329, N370, N421, N430, N431, N432;
  wire   n189, n190, n82, n83, n85, n86, n87, n88, n89, n90, n91, n92, n93,
         n94, n95, n96, n97, n98, n99, n100, n101, n102, n103, n104, n105,
         n106, n107, n108, n109, n110, n111, n112, n113, n114, n115, n116,
         n117, n118, n119, n120, n121, n122, n123, n124, n125, n126, n127,
         n128, n129, n130, n131, n132, n133, n134, n135, n136, n137, n138,
         n139, n140, n141, n142, n143, n144, n145, n146, n147, n148, n149,
         n150, n151, n152, n153, n154, n155, n156, n157, n158, n159, n160,
         n161, n162, n164, n165, n166, n167, n168, n169, n170, n171, n172,
         n173, n174, n175, n176, n177, n178, n179, n180, n181, n182, n183,
         n184, n185, n186, n187;

  HS65_LL_NAND2X2 U82 ( .A(N50), .B(N223), .Z(n107) );
  HS65_LL_NOR4ABX4 U83 ( .A(n179), .B(n175), .C(N108), .D(N430), .Z(n169) );
  HS65_LL_IVX2 U84 ( .A(n184), .Z(n185) );
  HS65_LL_NOR2X6 U85 ( .A(n177), .B(n181), .Z(n173) );
  HS65_LL_OR3ABCX35 U86 ( .A(n147), .B(n146), .C(n145), .Z(N370) );
  HS65_LL_NOR2X5 U87 ( .A(n118), .B(n123), .Z(n109) );
  HS65_LL_OAI211X3 U88 ( .A(N21), .B(n116), .C(n103), .D(n130), .Z(n111) );
  HS65_LL_IVX2 U89 ( .A(N102), .Z(n86) );
  HS65_LL_NOR2X3 U91 ( .A(n166), .B(n172), .Z(n167) );
  HS65_LL_IVX4 U92 ( .A(n148), .Z(n149) );
  HS65_LL_NAND2X4 U93 ( .A(n117), .B(n148), .Z(n146) );
  HS65_LL_NAND2X4 U94 ( .A(n171), .B(n170), .Z(n147) );
  HS65_LL_BFX35 U95 ( .A(n113), .Z(N329) );
  HS65_LL_NAND4ABX6 U96 ( .A(n112), .B(n111), .C(n110), .D(n109), .Z(n113) );
  HS65_LL_AOI211X2 U97 ( .A(n157), .B(n138), .C(n137), .D(n136), .Z(n139) );
  HS65_LL_AOI21X2 U98 ( .A(n134), .B(n161), .C(n133), .Z(n140) );
  HS65_LL_NAND2X4 U99 ( .A(N108), .B(n98), .Z(n135) );
  HS65_LL_NAND2X5 U100 ( .A(N17), .B(n99), .Z(n116) );
  HS65_LL_NAND2X4 U101 ( .A(N69), .B(n97), .Z(n131) );
  HS65_LL_NAND2X4 U103 ( .A(N11), .B(N223), .Z(n99) );
  HS65_LL_NAND2X4 U104 ( .A(n150), .B(N223), .Z(n104) );
  HS65_LL_AOI21X3 U106 ( .A(N95), .B(n90), .C(n89), .Z(n95) );
  HS65_LL_NAND2X4 U107 ( .A(n164), .B(n150), .Z(n89) );
  HS65_LL_OAI22X3 U108 ( .A(N11), .B(n91), .C(N1), .D(n100), .Z(n93) );
  HS65_LL_OAI22X3 U109 ( .A(N37), .B(n102), .C(N50), .D(n108), .Z(n92) );
  HS65_LL_IVX4 U110 ( .A(N56), .Z(n108) );
  HS65_LL_IVX4 U111 ( .A(N43), .Z(n102) );
  HS65_LL_IVX4 U112 ( .A(N4), .Z(n100) );
  HS65_LL_IVX2 U113 ( .A(N17), .Z(n91) );
  HS65_LL_IVX4 U114 ( .A(N63), .Z(n87) );
  HS65_LL_IVX4 U115 ( .A(N24), .Z(n88) );
  HS65_LL_BFX13 U116 ( .A(n189), .Z(N421) );
  HS65_LL_OA12X4 U117 ( .A(n176), .B(n175), .C(n174), .Z(n190) );
  HS65_LL_AO112X4 U118 ( .A(n183), .B(n182), .C(n181), .D(n180), .Z(n186) );
  HS65_LL_NOR2X3 U119 ( .A(n183), .B(n178), .Z(n175) );
  HS65_LL_AOI211X2 U120 ( .A(N86), .B(N329), .C(n168), .D(n167), .Z(n178) );
  HS65_LL_NAND2X21 U121 ( .A(n174), .B(n173), .Z(N430) );
  HS65_LL_OAI12X3 U122 ( .A(n161), .B(n172), .C(n160), .Z(n179) );
  HS65_LL_IVX7 U123 ( .A(N370), .Z(n172) );
  HS65_LL_AOI21X2 U124 ( .A(n140), .B(n139), .C(N329), .Z(n141) );
  HS65_LL_AOI12X4 U126 ( .A(N21), .B(N329), .C(n116), .Z(n148) );
  HS65_LL_OAI211X1 U127 ( .A(N53), .B(n130), .C(n129), .D(n128), .Z(n142) );
  HS65_LL_OR2X9 U128 ( .A(n121), .B(n120), .Z(n112) );
  HS65_LL_NOR2X5 U129 ( .A(n126), .B(n125), .Z(n110) );
  HS65_LL_NOR2X5 U130 ( .A(N86), .B(n168), .Z(n118) );
  HS65_LL_NOR2X5 U131 ( .A(N99), .B(n159), .Z(n125) );
  HS65_LL_NOR2X5 U132 ( .A(N73), .B(n131), .Z(n121) );
  HS65_LL_NOR2X5 U133 ( .A(N60), .B(n154), .Z(n123) );
  HS65_LL_NOR2X5 U134 ( .A(N34), .B(n132), .Z(n126) );
  HS65_LL_NAND2AX4 U136 ( .A(N47), .B(n157), .Z(n130) );
  HS65_LL_NAND2X5 U137 ( .A(N95), .B(n105), .Z(n159) );
  HS65_LL_NAND2X5 U140 ( .A(N102), .B(N223), .Z(n98) );
  HS65_LL_NAND2X5 U141 ( .A(n164), .B(N223), .Z(n97) );
  HS65_LL_AOI12X4 U142 ( .A(N37), .B(N223), .C(n102), .Z(n157) );
  HS65_LL_OR3ABCX27 U143 ( .A(n96), .B(n95), .C(n94), .Z(N223) );
  HS65_LL_NOR2X3 U144 ( .A(n93), .B(n92), .Z(n94) );
  HS65_LL_AOI22X3 U145 ( .A(N108), .B(n86), .C(N82), .D(n85), .Z(n96) );
  HS65_LL_NAND2X5 U146 ( .A(N30), .B(n88), .Z(n150) );
  HS65_LL_NAND2X5 U147 ( .A(N69), .B(n87), .Z(n164) );
  HS65_LL_IVX2 U148 ( .A(N223), .Z(n162) );
  HS65_LL_AOI12X2 U149 ( .A(N66), .B(N370), .C(n155), .Z(n177) );
  HS65_LL_AO12X4 U150 ( .A(N60), .B(N329), .C(n154), .Z(n155) );
  HS65_LL_AOI12X2 U151 ( .A(N53), .B(N370), .C(n158), .Z(n181) );
  HS65_LL_NAND2X2 U152 ( .A(n157), .B(n156), .Z(n158) );
  HS65_LL_NAND2X2 U153 ( .A(N69), .B(n162), .Z(n165) );
  HS65_LL_NAND2AX4 U154 ( .A(n108), .B(n107), .Z(n154) );
  HS65_LL_NAND2X2 U155 ( .A(N30), .B(n104), .Z(n132) );
  HS65_LL_IVX2 U156 ( .A(n114), .Z(n115) );
  HS65_LL_IVX2 U157 ( .A(N14), .Z(n171) );
  HS65_LL_AOI12X2 U158 ( .A(N27), .B(N370), .C(n149), .Z(n184) );
  HS65_LL_CBI4I1X3 U159 ( .A(N30), .B(n162), .C(n152), .D(n151), .Z(n153) );
  HS65_LL_IVX2 U160 ( .A(n150), .Z(n152) );
  HS65_LL_IVX2 U161 ( .A(n177), .Z(n182) );
  HS65_LL_IVX2 U162 ( .A(N27), .Z(n117) );
  HS65_LL_NAND2X2 U163 ( .A(n124), .B(n123), .Z(n129) );
  HS65_LL_AOI22X1 U164 ( .A(n127), .B(n126), .C(n125), .D(n161), .Z(n128) );
  HS65_LL_IVX2 U165 ( .A(N66), .Z(n124) );
  HS65_LL_AOI22X1 U166 ( .A(n122), .B(n121), .C(n120), .D(n119), .Z(n143) );
  HS65_LL_IVX2 U167 ( .A(N115), .Z(n119) );
  HS65_LL_IVX2 U168 ( .A(N79), .Z(n122) );
  HS65_LL_NAND2X2 U169 ( .A(n166), .B(n118), .Z(n144) );
  HS65_LL_NAND2X2 U170 ( .A(n101), .B(n114), .Z(n103) );
  HS65_LL_IVX2 U171 ( .A(N8), .Z(n101) );
  HS65_LL_IVX2 U172 ( .A(N89), .Z(n90) );
  HS65_LL_IVX2 U173 ( .A(N76), .Z(n85) );
  HS65_LL_OAI22X1 U174 ( .A(N40), .B(n132), .C(N79), .D(n131), .Z(n133) );
  HS65_LL_IVX2 U175 ( .A(n159), .Z(n134) );
  HS65_LL_IVX2 U176 ( .A(N105), .Z(n161) );
  HS65_LL_IVX2 U177 ( .A(N40), .Z(n127) );
  HS65_LL_IVX2 U178 ( .A(n173), .Z(n176) );
  HS65_LL_NOR4ABX4 U179 ( .A(n144), .B(n143), .C(n142), .D(n141), .Z(n145) );
  HS65_LL_NAND2X14 U180 ( .A(n82), .B(n185), .Z(N432) );
  HS65_LL_IVX2 U181 ( .A(n187), .Z(n83) );
  HS65_LL_AOI12X2 U182 ( .A(N40), .B(N370), .C(n153), .Z(n187) );
  HS65_LL_IVX13 U183 ( .A(n190), .Z(N431) );
  HS65_LL_CBI4I6X2 U184 ( .A(n172), .B(n171), .C(n170), .D(n169), .Z(n189) );
  HS65_LL_IVX2 U185 ( .A(N92), .Z(n166) );
  HS65_LL_OAI22X1 U186 ( .A(N66), .B(n154), .C(N115), .D(n135), .Z(n136) );
  HS65_LL_IVX2 U187 ( .A(N53), .Z(n138) );
  HS65_LL_NAND2X2 U188 ( .A(N47), .B(N329), .Z(n156) );
  HS65_LL_NAND2X2 U189 ( .A(N34), .B(N329), .Z(n151) );
  HS65_LL_NOR2X2 U190 ( .A(n179), .B(n178), .Z(n180) );
  HS65_LL_NOR2AX3 U191 ( .A(n166), .B(n168), .Z(n137) );
  HS65_LL_NOR2X6 U192 ( .A(n184), .B(n187), .Z(n174) );
  HS65_LL_AOI12X2 U193 ( .A(N99), .B(N329), .C(n159), .Z(n160) );
  HS65_LL_AOI222X2 U194 ( .A(n165), .B(n164), .C(N329), .D(N73), .E(N370), .F(
        N79), .Z(n183) );
  HS65_LL_NAND2X2 U105 ( .A(N76), .B(N223), .Z(n106) );
  HS65_LL_AOI12X3 U125 ( .A(N1), .B(N223), .C(n100), .Z(n114) );
  HS65_LL_NOR2X3 U135 ( .A(N112), .B(n135), .Z(n120) );
  HS65_LL_AOI12X3 U139 ( .A(N8), .B(N329), .C(n115), .Z(n170) );
  HS65_LL_NAND2X2 U90 ( .A(N89), .B(N223), .Z(n105) );
  HS65_LL_NAND2X4 U102 ( .A(N82), .B(n106), .Z(n168) );
  HS65_LL_NAND2X4 U138 ( .A(n186), .B(n83), .Z(n82) );
endmodule

