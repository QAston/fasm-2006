;============Dane==================================================
;==================================================================
PoparcieW: times 16 dt 0,0
Virtual at PoparcieW
PWpodlaskie dt 0,0
PWwarminskomazurskie dt 0,0
PWpomorskie dt 0,0
PWzachodniopomorskie dt 0,0
PWlubuskie dt 0,0
PWwielkopolskie dt 0,0
PWkujawskopomorskie dt 0,0
PWmazowieckie dt 0,0
PWlubelskie dt 0,0
PWpodkarpackie dt 0,0
PWswietokrzyskie dt 0,0
PWlodzkie dt 0,0
PWmalopolskie dt 0,0
PWslaskie dt 0,0
PWopolskie dt 0,0
PWdolnoslaskie dt 0,0
end virtual
;==================================================================
PoparcieM: times 49 dt 0,0
virtual at PoparcieM
PMsuwalki dt 0,0
PMolsztyn dt 0,0
PMelblag dt 0,0
PMgdansk dt 0,0
PMslupsk dt 0,0
PMkoszalin dt 0,0
PMszczecin dt 0,0
PMgorzowwlkp dt 0,0
PMpila dt 0,0
PMbydgoszcz dt 0,0
PMtorun dt 0,0
PMciechanow dt 0,0
PMostroleka dt 0,0
PMlomza dt 0,0
PMbialystok dt 0,0
PMbialapodlaska dt 0,0
PMsiedlce dt 0,0
PMwarszawa dt 0,0
PMplock dt 0,0
PMwloclawek dt 0,0
PMkonin dt 0,0
PMpoznan dt 0,0
PMzielonagora dt 0,0
PMleszno dt 0,0
PMkalisz dt 0,0
PMsieradz dt 0,0
PMlodz dt 0,0
PMpiotrkowtryb dt 0,0
PMskierniewice dt 0,0
PMradom dt 0,0
PMlublin dt 0,0
PMchelm dt 0,0
PMzamosc dt 0,0
PMtarnobrzeg dt 0,0
PMkielce dt 0,0
PMczestochowa dt 0,0
PMopole dt 0,0
PMwroclaw dt 0,0
PMlegnica dt 0,0
PMjeleniagora dt 0,0
PMwalbrzych dt 0,0
PMkatowice dt 0,0
PMkrakow dt 0,0
PMtarnow dt 0,0
PMrzeszow dt 0,0
PMprzemysl dt 0,0
PMkrosno dt 0,0
PMnowysacz dt 0,0
PMbielskobiala dt 0,0
end virtual
;==================================================================
PPO equ 0
PPIS equ 1
PLPR equ 2
PSLD equ 3
PPSL equ 4
PSO equ 5
PSDPL equ 6
PPartia1 equ 7
PPartia2 equ 8
PPartia3 equ 9
PPartia4 equ 10
PPartia5 equ 11
PPartia6 equ 12
PPartia7 equ 13
PPartia8 equ 14
PPartia9 equ 15
PPartia10 equ 16
PPartia11 equ 17
PPartia12 equ 18
PPartia equ 19
;==================================================================
;==================================================================
StrukturaW: times 16 dt 0,0
Virtual at StrukturaW
SWpodlaskie dt 0,0
SWwarminskomazurskie dt 0,0
SWpomorskie dt 0,0
SWzachodniopomorskie dt 0,0
SWlubuskie dt 0,0
SWwielkopolskie dt 0,0
SWkujawskopomorskie dt 0,0
SWmazowieckie dt 0,0
SWlubelskie dt 0,0
SWpodkarpackie dt 0,0
SWswietokrzyskie dt 0,0
SWlodzkie dt 0,0
SWmalopolskie dt 0,0
SWslaskie dt 0,0
SWopolskie dt 0,0
SWdolnoslaskie dt 0,0
end virtual
;==================================================================
StrukturaM: times 49 dt 0,0
virtual at StrukturaM
SMsuwalki dt 0,0
SMolsztyn dt 0,0
SMelblag dt 0,0
SMgdansk dt 0,0
SMslupsk dt 0,0
SMkoszalin dt 0,0
SMszczecin dt 0,0
SMgorzowwlkp dt 0,0
SMpila dt 0,0
SMbydgoszcz dt 0,0
SMtorun dt 0,0
SMciechanow dt 0,0
SMostroleka dt 0,0
SMlomza dt 0,0
SMbialystok dt 0,0
SMbialapodlaska dt 0,0
SMsiedlce dt 0,0
SMwarszawa dt 0,0
SMplock dt 0,0
SMwloclawek dt 0,0
SMkonin dt 0,0
SMpoznan dt 0,0
SMzielonagora dt 0,0
SMleszno dt 0,0
SMkalisz dt 0,0
SMsieradz dt 0,0
SMlodz dt 0,0
SMpiotrkowtryb dt 0,0
SMskierniewice dt 0,0
SMradom dt 0,0
SMlublin dt 0,0
SMchelm dt 0,0
SMzamosc dt 0,0
SMtarnobrzeg dt 0,0
SMkielce dt 0,0
SMczestochowa dt 0,0
SMopole dt 0,0
SMwroclaw dt 0,0
SMlegnica dt 0,0
SMjeleniagora dt 0,0
SMwalbrzych dt 0,0
SMkatowice dt 0,0
SMkrakow dt 0,0
SMtarnow dt 0,0
SMrzeszow dt 0,0
SMprzemysl dt 0,0
SMkrosno dt 0,0
SMnowysacz dt 0,0
SMbielskobiala dt 0,0
end virtual
;==================================================================
SBezrobotni equ 0
SRolnicy equ 1
SDzieci equ 2
SMlodzierz equ 3
SC1 equ 4
SC2 equ 5
SC3 equ 6
SC4 equ 7
SC5 equ 8
SC6 equ 9
SC7 equ 10
SC8 equ 11
SC9 equ 12
SC10 equ 13
SC11 equ 14
SC12 equ 15
SC13 equ 16
SC14 equ 17
SC15 equ 18
SC16 equ 19
;==================================================================
CharPrzecBezr: times 10 db 0
CharPrzecRol: times 10 db 0
CharPrzecDzie: times 10 db 0
CharPrzecMlod: times 10 db 0
CharPrzecC1: times 10 db 0
CharPrzecC2: times 10 db 0
CharPrzecC3: times 10 db 0
CharPrzecC4: times 10 db 0
CharPrzecC5: times 10 db 0
CharPrzecC6: times 10 db 0
CharPrzecC7: times 10 db 0
CharPrzecC8: times 10 db 0
CharPrzecC9: times 10 db 0
CharPrzecC10: times 10 db 0
CharPrzecC11: times 10 db 0
CharPrzecC12: times 10 db 0
CharPrzecC13: times 10 db 0
CharPrzecC14: times 10 db 0
CharPrzecC15: times 10 db 0
CharPrzecC16: times 10 db 0
;==================================================================
;==================================================================
PoziomZyciaW: times 16 dq 0
virtual at PoziomZyciaW
PZWpodlaskie dq 0
PZWwarminskomazurskie dq 0
PZWpomorskie dq 0
PZWzachodniopomorskie dq 0
PZWlubuskie dq 0
PZWwielkopolskie dq 0
PZWkujawskopomorskie dq 0
PZWmazowieckie dq 0
PZWlubelskie dq 0
PZWpodkarpackie dq 0
PZWswietokrzyskie dq 0
PZWlodzkie dq 0
PZWmalopolskie dq 0
PZWslaskie dq 0
PZWopolskie dq 0
PZWdolnoslaskie dq 0
end virtual
;==================================================================
PZogolne equ 0
PZbogactwo equ 1
PZinfrastruktura equ 2
PZzatrudnieni equ 3
PZkultura equ 4
PZtechnologia equ 5
PZzadowolenie equ 6
PZzarobkinaceny equ 7
;==================================================================
;==================================================================
ProgramPartii: times 20 dt 0,0
virtual at ProgramPartii
PPPO dt 0,0
PPPIS dt 0,0
PPLPR dt 0,0
PPSLD dt 0,0
PPPSL dt 0,0
PPSO dt 0,0
PPSDPL dt 0,0
PPPartia1 dt 0,0
PPPartia2 dt 0,0
PPPartia3 dt 0,0
PPPartia4 dt 0,0
PPPartia5 dt 0,0
PPPartia6 dt 0,0
PPPartia7 dt 0,0
PPPartia8 dt 0,0
PPPartia9 dt 0,0
PPPartia10 dt 0,0
PPPartia11 dt 0,0
PPPartia12 dt 0,0
PPPartia dt 0,0
end virtual
;
;
;trzeba scharakteryzowaæ bity do programu partii
;
;
;==================================================================
;==================================================================
KampaniaWyborcza: times 20 dt 0,0
virtual at KampaniaWyborcza
KWPO dt 0,0
KWPIS dt 0,0
KWLPR dt 0,0
KWSLD dt 0,0
KWPSL dt 0,0
KWSO dt 0,0
KWSDPL dt 0,0
KWPartia1 dt 0,0
KWPartia2 dt 0,0
KWPartia3 dt 0,0
KWPartia4 dt 0,0
KWPartia5 dt 0,0
KWPartia6 dt 0,0
KWPartia7 dt 0,0
KWPartia8 dt 0,0
KWPartia9 dt 0,0
KWPartia10 dt 0,0
KWPartia11 dt 0,0
KWPartia12 dt 0,0
KWPartia dt 0,0
end virtual
;
;
;trzeba scharakteryzowaæ bity do kampanii wyborczej
;
;
;==================================================================
;==================================================================
DData: dq 0
virtual at DData
DDzien db 0
DMies db 0
DRok dw 0
end virtual
Prezydent: times 20 db 0
Premier: times 20 db 0
;==================================================================
;==================================================================
