global pnadc "\\srjn4\area_corporativa\PNAD\PNAD Continua\Bases\Bases_primarias_PNADC\Entr5"

cd "\\srjn4\area_corporativa\MTRAB II\Pnad_C_projetos\Orientacao_sexual_horas_trab\Bases"

use domicilioid peso ano ocup desocup inativo pos_ocup vd4009 salmt_habt prev reg vd3004 vd4031 v4121b genero reg_pme uf rm_ride idade v2005 v2007 v2010 cor v1022 v1023 using "${pnadc}\pnadc_2016_entr5_def.dta", clear
// depois vamos fazer de novo com base de 1ª entrevista ou trimestral
append using "${pnadc}\pnadc_2018_entr5_def.dta", keep(domicilioid peso ano ocup desocup inativo pos_ocup vd4009 salmt_habt prev reg reg_pme uf vd3004 vd4031 v4121b genero rm_ride idade v2005 v2007 v2010 cor v1022 v1023)
append using "${pnadc}\pnadc_2017_entr5_def.dta", keep(domicilioid peso ano ocup desocup inativo pos_ocup vd4009 salmt_habt prev reg reg_pme uf vd3004 vd4031 v4121b genero rm_ride idade v2005 v2007 v2010 cor v1022 v1023)


// fazer indicadoras para pessoa de referencia e conjuges do mesmo sexo e de sexo diferente
gen pes_ref = v2005 == 1
gen conj = inlist(v2005,2,3)
gen conj_msexo = v2005 == 3
gen n_filhos = inlist(v2005,4,5,6)

// definir variáveis de interesse para pessoa de referência e conjuge

gen genero_pes_ref = v2007 if pes_ref == 1 // = 1 homem,= 2 mulher
gen genero_conj = v2007 if conj == 1

gen idade_pes_ref = idade if pes_ref == 1 
gen idade_conj = idade if conj == 1

/* variavel v2010
1	Branca
2	Preta
3	Amarela
4	Parda 
5	Indígena
9	Ignorado*/

gen cor_pes_ref = v2010 if pes_ref == 1
gen cor_conj = v2010 if conj == 1

/* variavel vd3004
1	Sem instrução e menos de 1 ano de estudo
2	Fundamental incompleto ou equivalente
3	Fundamental completo ou equivalente
4	Médio incompleto ou equivalente
5	Médio completo ou equivalente
6	Superior incompleto ou equivalente
7	Superior completo 
	Não aplicável*/

gen escol_pes_ref = vd3004 if pes_ref == 1
gen escol_conj = vd3004 if conj == 1

gen ocup_pes_ref = ocup if pes_ref == 1
gen ocup_conj = ocup if conj == 1

gen inativo_pes_ref = inativo if pes_ref == 1
gen inativo_conj = inativo if conj == 1

/* variavel vd4009
01	Empregado no setor privado com carteira de trabalho assinada
02	Empregado no setor privado sem carteira de trabalho assinada
03	Trabalhador doméstico com carteira de trabalho assinada
04	Trabalhador doméstico sem carteira de trabalho assinada
05	Empregado no setor público com carteira de trabalho assinada
06	Empregado no setor público sem carteira de trabalho assinada
07	Militar e servidor estatutário
08	Empregador
09	Conta-própria
10	Trabalhador familiar auxiliar
	Não aplicável*/

gen pos_ocup_pes_ref = vd4009 if pes_ref == 1
gen pos_ocup_conj = vd4009 if conj == 1

gen salmt_habt_pes_ref = salmt_habt if pes_ref == 1
gen salmt_habt_conj = salmt_habt if conj == 1

gen horas_trab_pes_ref = vd4031 if pes_ref == 1
gen horas_trab_conj = vd4031 if conj == 1

gen horas_tdom_pes_ref = v4121b if pes_ref == 1
gen horas_tdom_conj = v4121b if conj == 1

gen sal_hora_pes_efet = (salmt_habt/ (vd4031 * 4.3)) if pes_ref == 1
gen sal_hora_conj = (salmt_habt/ (vd4031 * 4.3)) if conj == 1 

// Além disso manter variáveis de regiao que não mudam dentro do casal

rename v1022 urbana // urbana=1 e rural==2
destring urbana, replace

gen reg1 = 1 if reg == "RENO"
replace reg1 = 2 if reg == "RENE"
replace reg1 = 3 if reg == "RESE"
replace reg1 = 4 if reg == "RSUL"
replace reg1 = 5 if reg == "RECO" 

destring v1023, replace
gen capital = 1 if v1023 == 1

// agregar a base em domicílios

collapse (sum) pes_ref conj conj_msexo genero_pes_ref genero_conj idade_pes_ref idade_conj cor_pes_ref cor_conj escol_pes_ref escol_conj ocup_pes_ref ocup_conj ///
	inativo_pes_ref inativo_conj pos_ocup_pes_ref pos_ocup_conj salmt_habt_pes_ref salmt_habt_conj horas_trab_pes_ref horas_trab_conj horas_tdom_pes_ref horas_tdom_conj ///
	sal_hora_pes_efet sal_hora_conj n_filhos ///
	(max) urbana capital reg_pme reg1 uf, by(domicilioid ano)
	
// deixar apenas domicilios com casais
keep if (pes_ref == 1 & conj == 1)

// fazer diferença entre horas trabalhadas
gen dif_horas_trab = abs(horas_trab_pes_ref - horas_trab_conj)
gen dif_horas_tdom = abs(horas_tdom_pes_ref - horas_tdom_conj)

// definir quem é chefe de familia 
egen horas_cf = rowmax(horas_trab_pes_ref horas_trab_conj)
egen horas_parceiro = rowmin(horas_trab_pes_ref horas_trab_conj)

gen chefe_pr = horas_cf==horas_trab_pes_ref

gen horas_dom_cf = horas_tdom_pes_ref if chefe_pr==1
replace horas_dom_cf = horas_tdom_conj if chefe_pr==0

gen horas_dom_parceiro = horas_tdom_pes_ref if chefe_pr==0
replace horas_dom_parceiro = horas_tdom_conj if chefe_pr==1

// separando casais sem filho
gen conj_msexo2 = conj_msexo if n_filhos==0

// para contar 
gen casal = 1
// salvar base pronta
save "\\srjn4\area_corporativa\MTRAB II\Pnad_C_projetos\Orientacao_sexual_horas_trab\Bases\base_orient_sexual_v2.dta", replace

// média da diferença e do chefe de familia e conjuge
preserve
collapse (mean) dif_horas_trab dif_horas_tdom horas_cf horas_parceiro horas_dom_cf horas_dom_parceiro (rawsum) casal, by(ano conj_msexo)
export excel using "\\srjn4\area_corporativa\MTRAB II\Pnad_C_projetos\Orientacao_sexual_horas_trab\Resultados\Tabelas_v2.xlsx", sheet("dados1") sheetmodify cell(B2) firstrow(variables)
restore

preserve
collapse (semean) dif_horas_trab dif_horas_tdom horas_cf horas_parceiro horas_dom_cf horas_dom_parceiro, by(ano conj_msexo)
export excel using "\\srjn4\area_corporativa\MTRAB II\Pnad_C_projetos\Orientacao_sexual_horas_trab\Resultados\Tabelas_v2.xlsx", sheet("dados1") sheetmodify cell(B12) firstrow(variables)
restore

preserve
collapse (mean) dif_horas_trab dif_horas_tdom horas_cf horas_parceiro horas_dom_cf horas_dom_parceiro (rawsum) casal if conj_msexo2!=., by(ano conj_msexo2)
export excel using "\\srjn4\area_corporativa\MTRAB II\Pnad_C_projetos\Orientacao_sexual_horas_trab\Resultados\Tabelas_v2.xlsx", sheet("dados1") sheetmodify cell(B22) firstrow(variables)
restore

preserve
collapse (semean) dif_horas_trab dif_horas_tdom horas_cf horas_parceiro horas_dom_cf horas_dom_parceiro if conj_msexo2!=., by(ano conj_msexo2)
export excel using "\\srjn4\area_corporativa\MTRAB II\Pnad_C_projetos\Orientacao_sexual_horas_trab\Resultados\Tabelas_v2.xlsx", sheet("dados1") sheetmodify cell(B32) firstrow(variables)
restore


