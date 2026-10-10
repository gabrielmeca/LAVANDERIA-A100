# Tabela de carga: quadro trifásico da lavanderia (220 V)

**Alimentação:** trifásica 3F + N + PE, 127/220 V, 60 Hz
**Referência:** ABNT NBR 5410. Cabos de cobre com isolação PVC 70 °C, instalados em eletroduto (método B1), temperatura ambiente de 30 °C.
**Fator de demanda:** 1,0. Numa lavanderia todas as máquinas podem funcionar ao mesmo tempo.

## 1. Premissas de cálculo

| Equipamento | Ligação | Potência | FP adotado | Fórmula da corrente |
|---|---|---|---|---|
| Secadora My Bubble | Bifásica 220 V (F-F) | 4.600 W | 1,00 (resistência de aquecimento) | I = P / 220 |
| Lavadora My Bubble | Bifásica 220 V (F-F) | 1.300 W | 0,85 (motor) | I = P / (220 × FP) |
| Lavadora/Secadora Oasis | Trifásica 220 V | 11.000 W | 1,00 (resistência de aquecimento) | I = P / (√3 × 220 × FP) |

> Confira na placa ou no manual de cada máquina a corrente nominal e o disjuntor recomendado pelo fabricante. Quando o fabricante pedir um valor **maior**, use o valor dele.

## 2. Tabela de carga por circuito

| Circ. | Descrição | Fases | Potência (W) | Potência (VA) | Corrente Ib (A) | Disjuntor | Cabo fase (mm²) | Cabo PE (mm²) | DR |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Secadora 1 My Bubble | R-S | 4.600 | 4.600 | 20,9 | Bipolar **25 A** curva C | **4,0** | 4,0 | Bipolar 25 A / 30 mA |
| 2 | Secadora 2 My Bubble | S-T | 4.600 | 4.600 | 20,9 | Bipolar **25 A** curva C | **4,0** | 4,0 | Bipolar 25 A / 30 mA |
| 3 | Secadora 3 My Bubble | T-R | 4.600 | 4.600 | 20,9 | Bipolar **25 A** curva C | **4,0** | 4,0 | Bipolar 25 A / 30 mA |
| 4 | Lavadora 1 My Bubble | R-S | 1.300 | 1.529 | 7,0 | Bipolar **10 A** curva C | **2,5** | 2,5 | Bipolar 25 A / 30 mA |
| 5 | Lavadora 2 My Bubble | S-T | 1.300 | 1.529 | 7,0 | Bipolar **10 A** curva C | **2,5** | 2,5 | Bipolar 25 A / 30 mA |
| 6 | Lavadora 3 My Bubble | T-R | 1.300 | 1.529 | 7,0 | Bipolar **10 A** curva C | **2,5** | 2,5 | Bipolar 25 A / 30 mA |
| 7 | Lavadora/Secadora Oasis | R-S-T | 11.000 | 11.000 | 28,9 | Tripolar **40 A** curva C | **10,0** | 10,0 | Tetrapolar 40 A / 30 mA |
| **G** | **Disjuntor geral** | **R-S-T** | **28.700** | **29.387** | **≈ 77** | **Tripolar 100 A curva C** | **35,0** (3 fases) + 25,0 (neutro) | **16,0** | — |

### Como cada circuito foi verificado (Ib ≤ In ≤ Iz)

| Circuito | Ib (A) | In do disjuntor (A) | Iz do cabo, B1 (A) | Resultado |
|---|---|---|---|---|
| Secadora (4 mm², 2 condutores carregados) | 20,9 | 25 | 32 | OK |
| Lavadora (2,5 mm², 2 condutores carregados) | 7,0 | 10 | 24 | OK |
| Oasis (10 mm², 3 condutores carregados) | 28,9 | 40 | 50 | OK, com folga para partida do motor e FP abaixo de 1 |
| Geral (35 mm², 3 condutores carregados) | 77 | 100 | 111 | OK |

- O geral de 80 A com cabo de 25 mm² (Iz = 89 A) também passaria na conta. Só que o disjuntor ficaria com 96 % da carga o tempo todo e poderia desarmar por aquecimento. Por isso a recomendação é **100 A com 35 mm²**.
- Se passar mais de um circuito no mesmo eletroduto, aplique o fator de agrupamento da NBR 5410. Exemplo: 3 circuitos juntos, fator 0,70. Para as secadoras, o melhor é usar um eletroduto para cada uma ou subir o cabo para **6 mm²**.
- **Queda de tensão:** os cabos acima atendem trechos de até cerca de 20 m entre o quadro e a máquina, com queda abaixo de 4 %. Para distâncias maiores, refaça a conta e aumente a bitola.

## 3. Balanceamento: corrente em cada fase

As máquinas bifásicas foram distribuídas em rodízio (R-S, S-T, T-R). Assim cada fase recebe exatamente a mesma carga.

Potência aparente por fase, com cada carga bifásica dividida meio a meio entre suas duas fases:

| Carga | Fase R (VA) | Fase S (VA) | Fase T (VA) |
|---|---|---|---|
| Secadora 1 (R-S) | 2.300 | 2.300 | — |
| Secadora 2 (S-T) | — | 2.300 | 2.300 |
| Secadora 3 (T-R) | 2.300 | — | 2.300 |
| Lavadora 1 (R-S) | 765 | 765 | — |
| Lavadora 2 (S-T) | — | 765 | 765 |
| Lavadora 3 (T-R) | 765 | — | 765 |
| Oasis (R-S-T) | 3.667 | 3.667 | 3.667 |
| **Total por fase** | **9.797 VA** | **9.797 VA** | **9.797 VA** |
| **Corrente por fase** (VA ÷ 127 V) | **≈ 77 A** | **≈ 77 A** | **≈ 77 A** |

**Resultado: cerca de 77 A em cada fase (R, S e T), com desequilíbrio de 0 %.**

Detalhe da corrente de linha em cada fase:

- Secadoras: 20,9 A × √3 = 36,2 A
- Lavadoras: 7,0 A × √3 = 12,0 A
- Oasis: 28,9 A
- **Soma: ≈ 77 A por fase.** Pela soma vetorial a corrente fica em ≈ 75,6 A. O valor de 77 A é um pouco maior, ou seja, fica a favor da segurança.

**Neutro:** nenhuma das máquinas usa o neutro, porque todas são ligadas entre fases. Na prática a corrente no neutro é próxima de zero. O neutro de 25 mm² no ramal fica disponível para tomadas e iluminação de 127 V, se houver.

## 4. Lista de materiais do quadro

| Item | Quantidade |
|---|---|
| Disjuntor tripolar 100 A curva C (geral, 10 kA) | 1 |
| Disjuntor bipolar 25 A curva C (secadoras) | 3 |
| Disjuntor bipolar 10 A curva C (lavadoras) | 3 |
| Disjuntor tripolar 40 A curva C (Oasis) | 1 |
| DR bipolar 25 A / 30 mA (um para cada máquina My Bubble) | 6 |
| DR tetrapolar 40 A / 30 mA (Oasis) | 1 |
| DPS classe II, 275 V, 20 kA (1 por fase + 1 para o neutro) | 4 |
| Barramento trifásico 100 A + barra de neutro + barra de terra | 1 conjunto |
| Cabo 35 mm² (fases do ramal geral) | 3 × comprimento do ramal |
| Cabo 25 mm² azul (neutro do ramal geral) | 1 × comprimento do ramal |
| Cabo 16 mm² verde (terra do ramal geral) | 1 × comprimento do ramal |
| Cabo 10 mm² (Oasis: 3 fases + PE) | 4 × comprimento |
| Cabo 4 mm² (secadoras: 2 fases + PE) | 3 × 3 × comprimento |
| Cabo 2,5 mm² (lavadoras: 2 fases + PE) | 3 × 3 × comprimento |

## 5. Observações importantes

1. **DR é obrigatório.** A NBR 5410 (item 5.1.3.2.2) exige DR de 30 mA em circuitos de áreas molhadas, como lavanderias. É melhor usar um DR por máquina do que um DR geral: a fuga somada das resistências pode fazer um DR geral desarmar sem motivo, e um defeito numa máquina derrubaria todas.
2. **Aterramento.** Todas as máquinas precisam ser ligadas ao condutor de proteção (PE), e o sistema de aterramento precisa estar verificado.
3. **Concessionária.** A carga instalada é de cerca de 28,7 kW em 220 V trifásico. Confirme com a distribuidora local a categoria do padrão de entrada e se o disjuntor de 100 A é compatível com o padrão existente. Se o padrão for menor, ele precisa ser readequado.
4. **Capacidade de interrupção.** Os disjuntores precisam ter Icu de pelo menos 5 kA nos circuitos terminais e 10 kA no geral. Confirme com o nível de curto-circuito do local.
5. Este dimensionamento é uma referência técnica. A execução deve ser feita e assinada por profissional habilitado (eletricista NR-10 / engenheiro com ART).
