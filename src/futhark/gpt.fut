--------- Generic Combinators ---------

def imap 'a : (n: i64) -> (i64 -> a) -> [n]a =
  \n f -> map f (iota n)

def imap1 = imap

def imap2 'a : (m: i64) -> (n: i64) -> (i64 -> i64 -> a) -> [m][n]a =
  \m n f -> imap m (\i -> imap n (f i))

def imap3 'a : (m: i64)
-> (n: i64)
-> (k: i64)
-> (i64 -> i64 -> i64 -> a) -> [m][n][k]a =
  \m n k f -> imap m (\i -> imap2 n k (f i))

def imap4 'a : (m: i64)
-> (n: i64)
-> (k: i64)
-> (l: i64)
-> (i64 -> i64 -> i64 -> i64 -> a) -> [m][n][k][l]a =
  \m n k l f -> imap m (\i -> imap3 n k l (f i))

def imap5 'a : (m: i64)
-> (n: i64)
-> (k: i64)
-> (l: i64)
-> (t: i64)
-> (i64 -> i64 -> i64 -> i64 -> i64 -> a) -> [m][n][k][l][t]a =
  \m n k l t f -> imap m (\i -> imap4 n k l t (f i))

def imap6 'a : (m: i64)
-> (n: i64)
-> (k: i64)
-> (l: i64)
-> (t: i64)
-> (p: i64)
-> (i64 -> i64 -> i64 -> i64 -> i64 -> i64 -> a) -> [m][n][k][l][t][p]a =
  \m n k l t p f -> imap m (\i -> imap5 n k l t p (f i))

def imap7 'a : (m: i64)
-> (n: i64)
-> (k: i64)
-> (l: i64)
-> (t: i64)
-> (p: i64)
-> (q: i64)
-> (i64 -> i64 -> i64 -> i64 -> i64 -> i64 -> i64 -> a) -> [m][n][k][l][t][p][q]a =
  \m n k l t p q f -> imap m (\i -> imap6 n k l t p q (f i))

def unzip7 [n] 'a 'b 'c 'd 'e 'f 'g : (a: [n](a, b, c, d, e, f, g)) -> ([n]a, [n]b, [n]c, [n]d, [n]e, [n]f, [n]g) =
  \a ->
    ( imap n (\i -> a[i].0)
    , imap n (\i -> a[i].1)
    , imap n (\i -> a[i].2)
    , imap n (\i -> a[i].3)
    , imap n (\i -> a[i].4)
    , imap n (\i -> a[i].5)
    , imap n (\i -> a[i].6)
    )

--==== MGPT Module ====--
module nn (F: real) = {
  type real = F.t

  def fromi64 (n: i64) = F.from_fraction n 1 -- why from fraction?
  def zero = fromi64 0
  def one = fromi64 1

  def isum1 : (m: i64) -> (i64 -> real) -> real =
    \m f -> loop r = zero for i < m do r F.+ f i

  def isum2 : (m: i64)
  -> (n: i64)
  -> (i64 -> i64 -> real) -> real =
    \m n f -> loop r = zero for i < m do r F.+ isum1 n (f i)

  def isum3 : (m: i64)
  -> (n: i64)
  -> (k: i64)
  -> (i64 -> i64 -> i64 -> real) -> real =
    \n m k f -> loop r = zero for i < n do r F.+ isum2 m k (f i)

  def isum4 : (m: i64)
  -> (n: i64)
  -> (k: i64)
  -> (l: i64)
  -> (i64 -> i64 -> i64 -> i64 -> real) -> real =
    \n m k l f -> loop r = zero for i < n do r F.+ isum3 m k l (f i)

  def isum5 : (m: i64)
  -> (n: i64)
  -> (k: i64)
  -> (l: i64)
  -> (t: i64)
  -> (i64 -> i64 -> i64 -> i64 -> i64 -> real) -> real =
    \n m k l t f -> loop r = zero for i < n do r F.+ isum4 m k l t (f i)

  def sum (a: []real) : real =
    reduce (F.+) zero a

  def imaximum1 : (m: i64) -> (i64 -> real) -> real =
    \m f -> F.maximum (imap1 m f)

  def imaximum2 : (m: i64)
  -> (n: i64)
  -> (i64 -> i64 -> real) -> real =
    \m n f -> F.maximum (imap1 m (\i -> imaximum1 n (f i)))

  def isoftmax1 (m: i64) (f : i64 -> real) : [m]real =
    #[inline]
    let max = imaximum1 m f
    let exps = imap1 m (\x -> F.exp((f x) F.+ F.neg max))
    let scale = isum1 m (\x -> exps[x])
    in imap1 m (\x -> exps[x] F./ scale)

  --==== 2d cases ====--
  def sum2d (a: [][]real) : real =
    sum (map sum a)

  --==== Logistics ====--
  def logistics : real -> real =
    \e -> one F./ (one F.+ F.exp (F.neg e))

  def sgnp : real -> real = \e -> F.sgn (F.max e zero)

  def indicatorp : real -> real = sgnp

  --==== This is the generated function. ====--

def forward_seq [bs]
  (wp: [16][16]real)
  (wqry: [16][16]real) (bqry: [16]real)
  (wkey: [16][16]real) (bkey: [16]real)
  (wval: [16][16]real) (bval: [16]real)
  (wo: [16][16]real)   (bo: [16]real)
  (mask: [16][16]real)
  (wu: [64][16]real)   (bu: [64]real)
  (wd: [16][64]real)   (bd: [16]real)
  (wc: [27][16]real)   (bc: [27]real)
  (ws: [bs][16][16]real)
  : [bs][16][27]real =
#[unsafe] --DANGER: Is this correct?
(imap1 bs (\i0 -> (let x1 = (imap1 16 (\i13 -> (let x14 = (imap1 16 (\i18 -> ((wp[i13][i18] F.+ ws[i0][i13][i18]) F.* (wp[i13][i18] F.+ ws[i0][i13][i18]))))
in (let x15 = ((isum1 16 (\i19 -> x14[i19])) F./ fromi64 16)
in (let x16 = (F.sqrt (x15 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i17 -> ((wp[i13][i17] F.+ ws[i0][i13][i17]) F.* (one F./ x16)))))))))
in (let x2 = (imap1 16 (\i20 -> (let x21 = (imap1 16 (\i25 -> (x1[i20][i25] F.* x1[i20][i25])))
in (let x22 = ((isum1 16 (\i26 -> x21[i26])) F./ fromi64 16)
in (let x23 = (F.sqrt (x22 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i24 -> (x1[i20][i24] F.* (one F./ x23)))))))))
in (let x3 = (imap1 16 (\i27 -> (imap1 16 (\i28 -> ((isum1 16 (\i29 -> (wqry[i28][i29] F.* x2[i27][i29]))) F.+ bqry[i28])))))
in (let x4 = (imap1 16 (\i30 -> (imap1 16 (\i31 -> ((isum1 16 (\i32 -> (wkey[i31][i32] F.* x2[i30][i32]))) F.+ bkey[i31])))))
in (let x5 = (imap1 16 (\i33 -> (imap1 16 (\i34 -> ((isum1 16 (\i35 -> (wval[i34][i35] F.* x2[i33][i35]))) F.+ bval[i34])))))
in (let x6 = (imap1 4 (\i36 -> (let x37 = (imap1 16 (\i39 -> (let x41 = (isoftmax1 16 (\i40 -> (((isum1 4 (\i43 -> (x3[i39][((i36 * 4) + i43)] F.* x4[i40][((i36 * 4) + i43)]))) F./ fromi64 2) F.+ mask[i39][i40])))
in (imap1 16 (\i42 -> x41[i42])))))
in (imap1 16 (\i38 -> (imap1 4 (\i44 -> (isum1 16 (\i45 -> (x37[i38][i45] F.* x5[i45][((i36 * 4) + i44)]))))))))))
in (let x7 = (imap1 16 (\i46 -> (imap1 16 (\i47 -> x6[(i47 / 4)][i46][(i47 % 4)]))))
in (let x8 = (imap1 16 (\i48 -> (imap1 16 (\i49 -> (x1[i48][i49] F.+ ((isum1 16 (\i50 -> (wo[i49][i50] F.* x7[i48][i50]))) F.+ bo[i49]))))))
in (let x9 = (imap1 16 (\i51 -> (let x52 = (imap1 16 (\i56 -> (x8[i51][i56] F.* x8[i51][i56])))
in (let x53 = ((isum1 16 (\i57 -> x52[i57])) F./ fromi64 16)
in (let x54 = (F.sqrt (x53 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i55 -> (x8[i51][i55] F.* (one F./ x54)))))))))
in (let x10 = (imap2 16 64 (\i58 i59 -> (F.max ((isum1 16 (\i60 -> (wu[i59][i60] F.* x9[i58][i60]))) F.+ bu[i59]) zero)))
in (let x11 = (imap1 16 (\i61 -> (imap1 16 (\i62 -> (x8[i61][i62] F.+ ((isum1 64 (\i63 -> (wd[i62][i63] F.* x10[i61][i63]))) F.+ bd[i62]))))))
in (imap1 16 (\i12 -> (imap1 27 (\i64 -> ((isum1 16 (\i65 -> (wc[i64][i65] F.* x11[i12][i65]))) F.+ bc[i64]))))))))))))))))))

def cal_loss [bs]
  (wp: [16][16]real)
  (wqry: [16][16]real) (bqry: [16]real)
  (wkey: [16][16]real) (bkey: [16]real)
  (wval: [16][16]real) (bval: [16]real)
  (wo: [16][16]real)   (bo: [16]real)
  (mask: [16][16]real)
  (wu: [64][16]real)   (bu: [64]real)
  (wd: [16][64]real)   (bd: [16]real)
  (wc: [27][16]real)   (bc: [27]real)
  (ws: [bs][16][16]real)
  (target: [bs][16][27]real)
  : real =

(let x0 = (imap1 bs (\i5 -> (let x6 = (imap1 16 (\i18 -> (let x19 = (imap1 16 (\i23 -> ((wp[i18][i23] F.+ ws[i5][i18][i23]) F.* (wp[i18][i23] F.+ ws[i5][i18][i23]))))
in (let x20 = ((isum1 16 (\i24 -> x19[i24])) F./ fromi64 16)
in (let x21 = (F.sqrt (x20 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i22 -> ((wp[i18][i22] F.+ ws[i5][i18][i22]) F.* (one F./ x21)))))))))
in (let x7 = (imap1 16 (\i25 -> (let x26 = (imap1 16 (\i30 -> (x6[i25][i30] F.* x6[i25][i30])))
in (let x27 = ((isum1 16 (\i31 -> x26[i31])) F./ fromi64 16)
in (let x28 = (F.sqrt (x27 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i29 -> (x6[i25][i29] F.* (one F./ x28)))))))))
in (let x8 = (imap1 16 (\i32 -> (imap1 16 (\i33 -> ((isum1 16 (\i34 -> (wqry[i33][i34] F.* x7[i32][i34]))) F.+ bqry[i33])))))
in (let x9 = (imap1 16 (\i35 -> (imap1 16 (\i36 -> ((isum1 16 (\i37 -> (wkey[i36][i37] F.* x7[i35][i37]))) F.+ bkey[i36])))))
in (let x10 = (imap1 16 (\i38 -> (imap1 16 (\i39 -> ((isum1 16 (\i40 -> (wval[i39][i40] F.* x7[i38][i40]))) F.+ bval[i39])))))
in (let x11 = (imap1 4 (\i41 -> (let x42 = (imap1 16 (\i44 -> (let x46 = (isoftmax1 16 (\i45 -> (((isum1 4 (\i48 -> (x8[i44][((i41 * 4) + i48)] F.* x9[i45][((i41 * 4) + i48)]))) F./ fromi64 2) F.+ mask[i44][i45])))
in (imap1 16 (\i47 -> x46[i47])))))
in (imap1 16 (\i43 -> (imap1 4 (\i49 -> (isum1 16 (\i50 -> (x42[i43][i50] F.* x10[i50][((i41 * 4) + i49)]))))))))))
in (let x12 = (imap1 16 (\i51 -> (imap1 16 (\i52 -> x11[(i52 / 4)][i51][(i52 % 4)]))))
in (let x13 = (imap1 16 (\i53 -> (imap1 16 (\i54 -> (x6[i53][i54] F.+ ((isum1 16 (\i55 -> (wo[i54][i55] F.* x12[i53][i55]))) F.+ bo[i54]))))))
in (let x14 = (imap1 16 (\i56 -> (let x57 = (imap1 16 (\i61 -> (x13[i56][i61] F.* x13[i56][i61])))
in (let x58 = ((isum1 16 (\i62 -> x57[i62])) F./ fromi64 16)
in (let x59 = (F.sqrt (x58 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i60 -> (x13[i56][i60] F.* (one F./ x59)))))))))
in (let x15 = (imap2 16 64 (\i63 i64 -> (F.max ((isum1 16 (\i65 -> (wu[i64][i65] F.* x14[i63][i65]))) F.+ bu[i64]) zero)))
in (let x16 = (imap1 16 (\i66 -> (imap1 16 (\i67 -> (x13[i66][i67] F.+ ((isum1 64 (\i68 -> (wd[i67][i68] F.* x15[i66][i68]))) F.+ bd[i67]))))))
in (imap1 16 (\i17 -> (imap1 27 (\i69 -> ((isum1 16 (\i70 -> (wc[i69][i70] F.* x16[i17][i70]))) F.+ bc[i69]))))))))))))))))))
in (let x1 = (imap3 bs 16 27 (\i71 i72 i73 -> (target[i71][i72][i73] F.* (F.neg (F.log (let x75 = (isoftmax1 27 (\i74 -> x0[i71][i72][i74]))
in x75[i73]))))))
in ((isum3 bs 16 27 (\i2 i3 i4 -> x1[i2][i3][i4])) F./ fromi64 (bs * 16))))

def grad [bs]
  (wp: [16][16]real)
  (wqry: [16][16]real) (bqry: [16]real)
  (wkey: [16][16]real) (bkey: [16]real)
  (wval: [16][16]real) (bval: [16]real)
  (wo: [16][16]real)   (bo: [16]real)
  (mask: [16][16]real)
  (wu: [64][16]real)   (bu: [64]real)
  (wd: [16][64]real)   (bd: [16]real)
  (wc: [27][16]real)   (bc: [27]real)
  (ws: [bs][16][16]real)
  (target: [bs][16][27]real) :
  (
  [bs][16][16]real,     -- ws
  [16][16]real,         -- position embedding
  [16][16]real, [16]real, -- query weights
  [16][16]real, [16]real, -- key weights
  [16][16]real, [16]real, -- val weights
  [16][16]real, [16]real, -- projection weights
  [64][16]real, [64]real, -- mpl up projection weights
  [16][64]real, [16]real, -- mlp down projection weights
  [27][16]real, [27]real  -- vocabulary projection weights
  ) =
let x0 = (imap1 bs (\i1 -> (let x2 = (imap1 16 (\i14 -> (let x15 = ((isum1 16 (\i18 -> ((wp[i14][i18] F.+ ws[i1][i14][i18]) F.* (wp[i14][i18] F.+ ws[i1][i14][i18])))) F./ fromi64 16)
in (let x16 = (F.sqrt (x15 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i17 -> ((wp[i14][i17] F.+ ws[i1][i14][i17]) F.* (one F./ x16))))))))
in (let x3 = (imap1 16 (\i19 -> (let x20 = ((isum1 16 (\i23 -> (x2[i19][i23] F.* x2[i19][i23]))) F./ fromi64 16)
in (let x21 = (F.sqrt (x20 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i22 -> (x2[i19][i22] F.* (one F./ x21))))))))
in (let x4 = (imap1 16 (\i24 -> (imap1 16 (\i25 -> ((isum1 16 (\i26 -> (wqry[i25][i26] F.* x3[i24][i26]))) F.+ bqry[i25])))))
in (let x5 = (imap1 16 (\i27 -> (imap1 16 (\i28 -> ((isum1 16 (\i29 -> (wkey[i28][i29] F.* x3[i27][i29]))) F.+ bkey[i28])))))
in (let x6 = (imap1 16 (\i30 -> (imap1 16 (\i31 -> ((isum1 16 (\i32 -> (wval[i31][i32] F.* x3[i30][i32]))) F.+ bval[i31])))))
in (let x7 = (imap1 4 (\i33 -> (let x34 = (imap1 16 (\i36 -> (let x38 = (isoftmax1 16 (\i37 -> (((isum1 4 (\i40 -> (x4[i36][((i33 * 4) + i40)] F.* x5[i37][((i33 * 4) + i40)]))) F./ fromi64 2) F.+ mask[i36][i37])))
in (imap1 16 (\i39 -> x38[i39])))))
in (imap1 16 (\i35 -> (imap1 4 (\i41 -> (isum1 16 (\i42 -> (x34[i35][i42] F.* x6[i42][((i33 * 4) + i41)]))))))))))
in (let x8 = (imap1 16 (\i43 -> (imap1 16 (\i44 -> x7[(i44 / 4)][i43][(i44 % 4)]))))
in (let x9 = (imap1 16 (\i45 -> (imap1 16 (\i46 -> (x2[i45][i46] F.+ ((isum1 16 (\i47 -> (wo[i46][i47] F.* x8[i45][i47]))) F.+ bo[i46]))))))
in (let x10 = (imap1 16 (\i48 -> (let x49 = ((isum1 16 (\i52 -> (x9[i48][i52] F.* x9[i48][i52]))) F./ fromi64 16)
in (let x50 = (F.sqrt (x49 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i51 -> (x9[i48][i51] F.* (one F./ x50))))))))
in (let x11 = (imap2 16 64 (\i53 i54 -> (F.max ((isum1 16 (\i55 -> (wu[i54][i55] F.* x10[i53][i55]))) F.+ bu[i54]) zero)))
in (let x12 = (imap1 16 (\i56 -> (imap1 16 (\i57 -> (x9[i56][i57] F.+ ((isum1 64 (\i58 -> (wd[i57][i58] F.* x11[i56][i58]))) F.+ bd[i57]))))))
in (imap1 16 (\i13 -> (imap1 27 (\i59 -> ((isum1 16 (\i60 -> (wc[i59][i60] F.* x12[i13][i60]))) F.+ bc[i59]))))))))))))))))))
let x61 = (imap3 bs 16 27 (\i62 i63 i64 -> (one F./ fromi64 (bs * 16))))
let x65 = (imap1 bs (\i66 -> (imap1 16 (\i67 -> (let x69 = (isoftmax1 27 (\i68 -> x0[i66][i67][i68]))
in (imap1 27 (\i70 -> x69[i70])))))))
let x71 = (imap1 bs (\i72 -> (imap1 16 (\i73 -> (imap1 27 (\i76 -> (F.neg ((target[i72][i73][i76] F.* x61[i72][i73][i76]) F.* (one F./ (let x75 = (isoftmax1 27 (\i74 -> x0[i72][i73][i74]))
in x75[i76]))))))))))
let x77 = (imap1 bs (\i78 -> (imap1 16 (\i79 -> (isum1 27 (\i80 -> (x71[i78][i79][i80] F.* x65[i78][i79][i80])))))))
let x81 = (imap1 bs (\i82 -> (imap1 16 (\i83 -> (imap1 27 (\i84 -> (x65[i82][i83][i84] F.* (x71[i82][i83][i84] F.+ (F.neg x77[i82][i83])))))))))
let x85 = (imap1 bs (\i86 -> (imap1 16 (\i87 -> (let x88 = ((isum1 16 (\i91 -> ((wp[i87][i91] F.+ ws[i86][i87][i91]) F.* (wp[i87][i91] F.+ ws[i86][i87][i91])))) F./ fromi64 16)
in (let x89 = (F.sqrt (x88 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i90 -> ((wp[i87][i90] F.+ ws[i86][i87][i90]) F.* (one F./ x89))))))))))
let x92 = (imap1 bs (\i93 -> (imap1 16 (\i94 -> (let x95 = ((isum1 16 (\i98 -> (x85[i93][i94][i98] F.* x85[i93][i94][i98]))) F./ fromi64 16)
in (let x96 = (F.sqrt (x95 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i97 -> (x85[i93][i94][i97] F.* (one F./ x96))))))))))
let x99 = (imap1 bs (\i100 -> (imap1 16 (\i101 -> (imap1 16 (\i102 -> ((isum1 16 (\i103 -> (wqry[i102][i103] F.* x92[i100][i101][i103]))) F.+ bqry[i102])))))))
let x104 = (imap1 bs (\i105 -> (imap1 16 (\i106 -> (imap1 16 (\i107 -> ((isum1 16 (\i108 -> (wkey[i107][i108] F.* x92[i105][i106][i108]))) F.+ bkey[i107])))))))
let x109 = (imap1 bs (\i110 -> (imap1 16 (\i111 -> (imap1 16 (\i112 -> ((isum1 16 (\i113 -> (wval[i112][i113] F.* x92[i110][i111][i113]))) F.+ bval[i112])))))))
let x114 = (imap1 bs (\i115 -> (imap1 4 (\i116 -> (let x117 = (imap1 16 (\i119 -> (let x121 = (isoftmax1 16 (\i120 -> (((isum1 4 (\i123 -> (x99[i115][i119][((i116 * 4) + i123)] F.* x104[i115][i120][((i116 * 4) + i123)]))) F./ fromi64 2) F.+ mask[i119][i120])))
in (imap1 16 (\i122 -> x121[i122])))))
in (imap1 16 (\i118 -> (imap1 4 (\i124 -> (isum1 16 (\i125 -> (x117[i118][i125] F.* x109[i115][i125][((i116 * 4) + i124)]))))))))))))
let x126 = (imap1 bs (\i127 -> (imap1 16 (\i128 -> (imap1 16 (\i129 -> x114[i127][(i129 / 4)][i128][(i129 % 4)]))))))
let x130 = (imap1 bs (\i131 -> (imap1 16 (\i132 -> (imap1 16 (\i133 -> (x85[i131][i132][i133] F.+ ((isum1 16 (\i134 -> (wo[i133][i134] F.* x126[i131][i132][i134]))) F.+ bo[i133]))))))))
let x135 = (imap1 bs (\i136 -> (imap1 16 (\i137 -> (let x138 = ((isum1 16 (\i141 -> (x130[i136][i137][i141] F.* x130[i136][i137][i141]))) F./ fromi64 16)
in (let x139 = (F.sqrt (x138 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i140 -> (x130[i136][i137][i140] F.* (one F./ x139))))))))))
let x142 = (imap1 bs (\i143 -> (imap2 16 64 (\i144 i145 -> (F.max ((isum1 16 (\i146 -> (wu[i145][i146] F.* x135[i143][i144][i146]))) F.+ bu[i145]) zero)))))
let x147 = (imap1 bs (\i148 -> (imap1 16 (\i149 -> (imap1 16 (\i150 -> (x130[i148][i149][i150] F.+ ((isum1 64 (\i151 -> (wd[i150][i151] F.* x142[i148][i149][i151]))) F.+ bd[i150]))))))))
let x152 = (imap1 bs (\i153 -> (imap1 16 (\i154 -> (imap1 16 (\i155 -> (isum1 27 (\i156 -> (wc[i156][i155] F.* x81[i153][i154][i156])))))))))
let x157 = (imap1 bs (\i158 -> (imap1 16 (\i159 -> (imap1 64 (\i160 -> (isum1 16 (\i161 -> (wd[i161][i160] F.* x152[i158][i159][i161])))))))))
let x162 = (imap1 bs (\i163 -> (imap1 16 (\i164 -> (imap1 16 (\i165 -> (isum1 64 (\i166 -> (wu[i166][i165] F.* ((indicatorp ((isum1 16 (\i167 -> (wu[i166][i167] F.* x135[i163][i164][i167]))) F.+ bu[i166])) F.* x157[i163][i164][i166]))))))))))
let x168 = (imap1 bs (\i169 -> (imap1 16 (\i170 -> (imap1 16 (\i171 -> (x130[i169][i170][i171] F.* x130[i169][i170][i171])))))))
let x172 = (imap1 bs (\i173 -> (imap1 16 (\i174 -> ((isum1 16 (\i175 -> x168[i173][i174][i175])) F./ fromi64 16)))))
let x176 = (imap1 bs (\i177 -> (imap1 16 (\i178 -> (F.sqrt (x172[i177][i178] F.+ (one F./ fromi64 100000)))))))
let x179 = (imap1 bs (\i180 -> (imap1 16 (\i181 -> (F.neg ((one F./ x176[i180][i181]) F.* ((isum1 16 (\i182 -> (x130[i180][i181][i182] F.* x162[i180][i181][i182]))) F.* (one F./ x176[i180][i181]))))))))
let x183 = (imap1 bs (\i184 -> (imap1 16 (\i185 -> (x179[i184][i185] F.* (one F./ ((one F.+ one) F.* (F.sqrt (x172[i184][i185] F.+ (one F./ fromi64 100000))))))))))
let x186 = (imap1 bs (\i187 -> (imap1 16 (\i188 -> (imap1 16 (\i189 -> (x183[i187][i188] F./ fromi64 16)))))))
let x190 = (imap1 bs (\i191 -> (imap1 16 (\i192 -> (imap1 16 (\i193 -> (x152[i191][i192][i193] F.+ (((x162[i191][i192][i193] F.* (one F./ x176[i191][i192])) F.+ (x130[i191][i192][i193] F.* x186[i191][i192][i193])) F.+ (x186[i191][i192][i193] F.* x130[i191][i192][i193])))))))))
let x194 = (imap1 bs (\i195 -> (imap1 16 (\i196 -> (imap1 16 (\i197 -> (isum1 16 (\i198 -> (wo[i198][i197] F.* x190[i195][i196][i198])))))))))
let x199 = (imap1 bs (\i200 -> (imap1 4 (\i201 -> (imap1 16 (\i202 -> (imap1 4 (\i203 -> x194[i200][i202][((i201 * 4) + i203)]))))))))
let x204 = (imap1 bs (\i205 -> (imap1 4 (\i206 -> (imap1 16 (\i207 -> (let x209 = (isoftmax1 16 (\i208 -> (((isum1 4 (\i211 -> (x99[i205][i207][((i206 * 4) + i211)] F.* x104[i205][i208][((i206 * 4) + i211)]))) F./ fromi64 2) F.+ mask[i207][i208])))
in (imap1 16 (\i210 -> x209[i210])))))))))
let x212 = (imap1 bs (\i213 -> (imap1 4 (\i214 -> (imap1 16 (\i215 -> (imap1 16 (\i216 -> (isum1 4 (\i217 -> (x199[i213][i214][i215][i217] F.* x109[i213][i216][((i214 * 4) + i217)])))))))))))
let x218 = (imap1 bs (\i219 -> (imap1 4 (\i220 -> (imap1 16 (\i221 -> (imap1 16 (\i222 -> x212[i219][i220][i221][i222]))))))))
let x223 = (imap1 bs (\i224 -> (imap1 4 (\i225 -> (imap1 16 (\i226 -> (isum1 16 (\i227 -> (x218[i224][i225][i226][i227] F.* x204[i224][i225][i226][i227])))))))))
let x228 = (imap1 bs (\i229 -> (imap1 16 (\i230 -> (imap1 16 (\i231 -> (isum1 16 (\i232 -> (x204[i229][(i231 / 4)][i232][i230] F.* x199[i229][(i231 / 4)][i232][(i231 % 4)])))))))))
let x233 = (imap1 bs (\i234 -> (imap1 16 (\i235 -> (imap1 16 (\i236 -> (isum1 16 (\i237 -> (x99[i234][i237][(((i236 / 4) * 4) + (i236 % 4))] F.* ((x204[i234][(i236 / 4)][i237][i235] F.* (x218[i234][(i236 / 4)][i237][i235] F.+ (F.neg x223[i234][(i236 / 4)][i237]))) F./ fromi64 2))))))))))
let x238 = (imap1 bs (\i239 -> (imap1 16 (\i240 -> (imap1 16 (\i241 -> (isum1 16 (\i242 -> (((x204[i239][(i241 / 4)][i240][i242] F.* (x218[i239][(i241 / 4)][i240][i242] F.+ (F.neg x223[i239][(i241 / 4)][i240]))) F./ fromi64 2) F.* x104[i239][i242][(((i241 / 4) * 4) + (i241 % 4))])))))))))
let x243 = (imap1 bs (\i244 -> (imap1 16 (\i245 -> (imap1 16 (\i246 -> (((isum1 16 (\i247 -> (wval[i247][i246] F.* x228[i244][i245][i247]))) F.+ (isum1 16 (\i248 -> (wkey[i248][i246] F.* x233[i244][i245][i248])))) F.+ (isum1 16 (\i249 -> (wqry[i249][i246] F.* x238[i244][i245][i249]))))))))))
let x250 = (imap1 bs (\i251 -> (imap1 16 (\i252 -> (imap1 16 (\i253 -> (x85[i251][i252][i253] F.* x85[i251][i252][i253])))))))
let x254 = (imap1 bs (\i255 -> (imap1 16 (\i256 -> ((isum1 16 (\i257 -> x250[i255][i256][i257])) F./ fromi64 16)))))
let x258 = (imap1 bs (\i259 -> (imap1 16 (\i260 -> (F.sqrt (x254[i259][i260] F.+ (one F./ fromi64 100000)))))))
let x261 = (imap1 bs (\i262 -> (imap1 16 (\i263 -> (F.neg ((one F./ x258[i262][i263]) F.* ((isum1 16 (\i264 -> (x85[i262][i263][i264] F.* x243[i262][i263][i264]))) F.* (one F./ x258[i262][i263]))))))))
let x265 = (imap1 bs (\i266 -> (imap1 16 (\i267 -> (x261[i266][i267] F.* (one F./ ((one F.+ one) F.* (F.sqrt (x254[i266][i267] F.+ (one F./ fromi64 100000))))))))))
let x268 = (imap1 bs (\i269 -> (imap1 16 (\i270 -> (imap1 16 (\i271 -> (x265[i269][i270] F./ fromi64 16)))))))
let x272 = (imap1 bs (\i273 -> (imap1 16 (\i274 -> (imap1 16 (\i275 -> (x190[i273][i274][i275] F.+ (((x243[i273][i274][i275] F.* (one F./ x258[i273][i274])) F.+ (x85[i273][i274][i275] F.* x268[i273][i274][i275])) F.+ (x268[i273][i274][i275] F.* x85[i273][i274][i275])))))))))
let x276 = (imap1 bs (\i277 -> (imap1 16 (\i278 -> (imap1 16 (\i279 -> ((wp[i278][i279] F.+ ws[i277][i278][i279]) F.* (wp[i278][i279] F.+ ws[i277][i278][i279]))))))))
let x280 = (imap1 bs (\i281 -> (imap1 16 (\i282 -> ((isum1 16 (\i283 -> x276[i281][i282][i283])) F./ fromi64 16)))))
let x284 = (imap1 bs (\i285 -> (imap1 16 (\i286 -> (F.sqrt (x280[i285][i286] F.+ (one F./ fromi64 100000)))))))
let x287 = (imap1 bs (\i288 -> (imap1 16 (\i289 -> (F.neg ((one F./ x284[i288][i289]) F.* ((isum1 16 (\i290 -> ((wp[i289][i290] F.+ ws[i288][i289][i290]) F.* x272[i288][i289][i290]))) F.* (one F./ x284[i288][i289]))))))))
let x291 = (imap1 bs (\i292 -> (imap1 16 (\i293 -> (x287[i292][i293] F.* (one F./ ((one F.+ one) F.* (F.sqrt (x280[i292][i293] F.+ (one F./ fromi64 100000))))))))))
let x294 = (imap1 bs (\i295 -> (imap1 16 (\i296 -> (imap1 16 (\i297 -> (x291[i295][i296] F./ fromi64 16)))))))

let dwp = (imap1 16 (\i298 -> (imap1 16 (\i299 -> (isum1 bs (\i300 -> (((x272[i300][i298][i299] F.* (one F./ x284[i300][i298])) F.+ ((wp[i298][i299] F.+ ws[i300][i298][i299]) F.* x294[i300][i298][i299])) F.+ (x294[i300][i298][i299] F.* (wp[i298][i299] F.+ ws[i300][i298][i299])))))))))
let dwqry = (imap1 16 (\i301 -> (imap1 16 (\i302 -> (isum1 bs (\i303 -> (isum1 16 (\i304 -> (x238[i303][i304][i301] F.* x92[i303][i304][i302])))))))))
let dwkey = (imap1 16 (\i305 -> (imap1 16 (\i306 -> (isum1 bs (\i307 -> (isum1 16 (\i308 -> (x233[i307][i308][i305] F.* x92[i307][i308][i306])))))))))
let dwval = (imap1 16 (\i309 -> (imap1 16 (\i310 -> (isum1 bs (\i311 -> (isum1 16 (\i312 -> (x228[i311][i312][i309] F.* x92[i311][i312][i310])))))))))
let dwo = (imap1 16 (\i313 -> (imap1 16 (\i314 -> (isum1 bs (\i315 -> (isum1 16 (\i316 -> (x190[i315][i316][i313] F.* x126[i315][i316][i314])))))))))
-- let dmask = (imap1 16 (\i317 -> (imap1 16 (\i320 -> (isum1 bs (\i318 -> (isum1 4 (\i319 -> (x204[i318][i319][i317][i320] F.* (x218[i318][i319][i317][i320] F.+ (F.neg x223[i318][i319][i317])))))))))))
let dwu = (imap1 64 (\i321 -> (imap1 16 (\i322 -> (isum1 bs (\i323 -> (isum1 16 (\i324 -> (((indicatorp ((isum1 16 (\i325 -> (wu[i321][i325] F.* x135[i323][i324][i325]))) F.+ bu[i321])) F.* x157[i323][i324][i321]) F.* x135[i323][i324][i322])))))))))
let dwd = (imap1 16 (\i326 -> (imap1 64 (\i327 -> (isum1 bs (\i328 -> (isum1 16 (\i329 -> (x152[i328][i329][i326] F.* x142[i328][i329][i327])))))))))
let dwc = (imap1 27 (\i330 -> (imap1 16 (\i331 -> (isum1 bs (\i332 -> (isum1 16 (\i333 -> (x81[i332][i333][i330] F.* x147[i332][i333][i331])))))))))
let dbqry = (imap1 16 (\i336 -> (isum1 bs (\i334 -> (isum1 16 (\i335 -> x238[i334][i335][i336]))))))
let dbkey = (imap1 16 (\i339 -> (isum1 bs (\i337 -> (isum1 16 (\i338 -> x233[i337][i338][i339]))))))
let dbval = (imap1 16 (\i342 -> (isum1 bs (\i340 -> (isum1 16 (\i341 -> x228[i340][i341][i342]))))))
let dbo = (imap1 16 (\i345 -> (isum1 bs (\i343 -> (isum1 16 (\i344 -> x190[i343][i344][i345]))))))
let dbu = (imap1 64 (\i348 -> (isum1 bs (\i346 -> (isum1 16 (\i347 -> ((indicatorp ((isum1 16 (\i349 -> (wu[i348][i349] F.* x135[i346][i347][i349]))) F.+ bu[i348])) F.* x157[i346][i347][i348])))))))
let dbd = (imap1 16 (\i352 -> (isum1 bs (\i350 -> (isum1 16 (\i351 -> x152[i350][i351][i352]))))))
let dbc = (imap1 27 (\i355 -> (isum1 bs (\i353 -> (isum1 16 (\i354 -> x81[i353][i354][i355]))))))
let dws = (imap1 bs (\i356 -> (imap1 16 (\i357 -> (imap1 16 (\i358 -> (((x272[i356][i357][i358] F.* (one F./ x284[i356][i357])) F.+ ((wp[i357][i358] F.+ ws[i356][i357][i358]) F.* x294[i356][i357][i358])) F.+ (x294[i356][i357][i358] F.* (wp[i357][i358] F.+ ws[i356][i357][i358])))))))))
-- let dtarget = (imap3 bs 16 27 (\i359 i360 i361 -> (x61[i359][i360][i361] F.* (F.neg (F.log (let x363 = (isoftmax1 27 (\i362 -> x0[i359][i360][i362]))
-- in x363[i361]))))))

in (dws, dwp, dwqry, dbqry, dwkey, dbkey, dwval, dbval, dwo, dbo, dwu, dbu, dwd, dbd, dwc, dbc)
}

module nn64 = nn f64

let sl : i64 = 16
let ed : i64 = 16
let ah : i64 = 4
let hd : i64 = 4
let fd : i64 = 64
let vo : i64 = 27

type params =
  {
  wt   : [vo][ed]f64,                    -- token embeddings
  wp   : [sl][ed]f64,                    -- position embeddings
  wqry : [ed][ed]f64, bqry : [ed]f64,    -- query weights
  wkey : [ed][ed]f64, bkey : [ed]f64,    -- key weights
  wval : [ed][ed]f64, bval : [ed]f64,    -- value weights
  wo   : [ed][ed]f64, bo   : [ed]f64,    -- output weights
  wu   : [fd][ed]f64, bu   : [fd]f64,    -- MLP up-projection
  wd   : [ed][fd]f64, bd   : [ed]f64,    -- MLP down-projection
  wc   : [vo][ed]f64, bc   : [vo]f64     -- output projection
  }

entry to_params
    (wt: [vo][ed]f64)
    (wp: [sl][ed]f64)
    (wqry: [ed][ed]f64) (bqry: [ed]f64)
    (wkey: [ed][ed]f64) (bkey: [ed]f64)
    (wval: [ed][ed]f64) (bval: [ed]f64)
    (wo: [ed][ed]f64) (bo: [ed]f64)
    (wu: [fd][ed]f64) (bu: [fd]f64)
    (wd: [ed][fd]f64) (bd: [ed]f64)
    (wc: [vo][ed]f64) (bc: [vo]f64) : params =
  {wt, wp, wqry, bqry, wkey, bkey, wval, bval, wo, bo, wu, bu, wd, bd, wc, bc}

def from_params (p : params) :
  (
  [vo][ed]f64,
  [sl][ed]f64,
  [ed][ed]f64, [ed]f64,
  [ed][ed]f64, [ed]f64,
  [ed][ed]f64, [ed]f64,
  [ed][ed]f64, [ed]f64,
  [fd][ed]f64, [fd]f64,
  [ed][fd]f64, [ed]f64,
  [vo][ed]f64, [vo]f64
  ) =
  let {wt, wp, wqry, bqry, wkey, bkey, wval, bval,
    wo, bo, wu, bu, wd, bd, wc, bc} = p
  in (wt, wp, wqry, bqry, wkey, bkey, wval, bval,
    wo, bo, wu, bu, wd, bd, wc, bc)

entry forward [bs] (p : params) (tokens : [bs][sl]i64) (mask : [sl][sl]f64) : [bs][sl][vo]f64 =
   let {wt, wp, wqry, bqry, wkey, bkey, wval, bval, wo, bo, wu, bu, wd, bd, wc, bc} = p
   let ws = (imap3 bs sl ed (\i j k -> wt[tokens[i][j]][k]))
   in (nn64.forward_seq
    (wp:> [16][16]f64)
    (wqry:> [16][16]f64) (bqry:> [16]f64)
    (wkey:> [16][16]f64) (bkey:> [16]f64)
    (wval:> [16][16]f64) (bval:> [16]f64)
    (wo:> [16][16]f64) (bo:> [16]f64)
    (mask :> [16][16]f64)
    (wu:> [64][16]f64) (bu:> [64]f64)
    (wd:> [16][64]f64) (bd:> [16]f64)
    (wc:> [27][16]f64) (bc:> [27]f64)
    (ws :> [bs][16][16]f64)
      :> [bs][sl][vo]f64)

entry cal_target [bs] (tokens : [bs][sl]i64) : [bs][sl]i64 =
  imap2 bs sl (\i j -> if (j < sl - 1) then tokens[i][j + 1] else vo)

entry cal_target_mask [bs] (n : i64) (target : [bs][sl]i64) : [bs][sl][vo]f64 =
  imap3 bs sl vo (\i j k -> (if ((j < (n - 1)) && (target[i][j] == k)) then 1 else 0))

entry loss [bs] (p : params) (tokens : [bs][sl]i64) (mask : [sl][sl]f64) : f64 =
   let {wt, wp, wqry, bqry, wkey, bkey, wval, bval, wo, bo, wu, bu, wd, bd, wc, bc} = p
   let target = cal_target_mask sl (cal_target tokens)
   let ws = (imap3 bs sl ed (\i j k -> wt[tokens[i][j]][k]))
   in (nn64.cal_loss
        (wp:> [16][16]f64)
        (wqry:> [16][16]f64) (bqry:> [16]f64)
        (wkey:> [16][16]f64) (bkey:> [16]f64)
        (wval:> [16][16]f64) (bval:> [16]f64)
        (wo:> [16][16]f64) (bo:> [16]f64)
        (mask :> [16][16]f64)
        (wu:> [64][16]f64) (bu:> [64]f64)
        (wd:> [16][64]f64) (bd:> [16]f64)
        (wc:> [27][16]f64) (bc:> [27]f64)
        (ws :> [bs][16][16]f64)
        (target :> [bs][16][27]f64)
                :> f64)

def grad [bs] (p : params) (tokens : [bs][sl]i64) (mask : [sl][sl]f64) :
        (
        [vo][ed]f64,
        [sl][ed]f64,
        [ed][ed]f64, [ed]f64,
        [ed][ed]f64, [ed]f64,
        [ed][ed]f64, [ed]f64,
        [ed][ed]f64, [ed]f64,
        [fd][ed]f64, [fd]f64,
        [ed][fd]f64, [ed]f64,
        [vo][ed]f64, [vo]f64
        ) =
   let {wt, wp, wqry, bqry, wkey, bkey, wval, bval, wo, bo, wu, bu, wd, bd, wc, bc} = p
   -- cal targets
   let target = cal_target_mask sl (cal_target tokens)
   -- cal voc embedding
   let ws = (imap3 bs sl ed (\i j k -> wt[tokens[i][j]][k]))
   -- cal gradient
   let (dws, dwp, dwqry, dbqry, dwkey, dbkey, dwval, dbval, dwo, dbo, dwu, dbu, dwd, dbd, dwc, dbc) =
    (nn64.grad
        (wp:> [16][16]f64)
        (wqry:> [16][16]f64) (bqry:> [16]f64)
        (wkey:> [16][16]f64) (bkey:> [16]f64)
        (wval:> [16][16]f64) (bval:> [16]f64)
        (wo:> [16][16]f64) (bo:> [16]f64)
        (mask :> [16][16]f64)
        (wu:> [64][16]f64) (bu:> [64]f64)
        (wd:> [16][64]f64) (bd:> [16]f64)
        (wc:> [27][16]f64) (bc:> [27]f64)
        (ws :> [bs][16][16]f64)
        (target :> [bs][16][27]f64)
                :>
        (
        [bs][sl][ed]f64, --ws
        [sl][ed]f64,
        [ed][ed]f64, [ed]f64,
        [ed][ed]f64, [ed]f64,
        [ed][ed]f64, [ed]f64,
        [ed][ed]f64, [ed]f64,
        [fd][ed]f64, [fd]f64,
        [ed][fd]f64, [ed]f64,
        [vo][ed]f64, [vo]f64
        ))
   let dwt = (imap2 vo ed (\m n -> nn64.isum2 bs sl (\i k -> if (tokens[i][k] == m) then dws[i][k][n] else 0)))
   in  (dwt, dwp, dwqry, dbqry, dwkey, dbkey, dwval, dbval, dwo, dbo, dwu, dbu, dwd, dbd, dwc, dbc)

def adam_opt1 [n]  (w : [n]f64) (mw : [n]f64) (vw : [n]f64)
  (dw : [n]f64) (step : i64) (lt_r : f64):
  ([n]f64, [n]f64, [n]f64) =
  let new_mw = imap1 n (\i -> 0.85 * mw[i] + ((1 - 0.85) * dw[i]))
  let new_vw = imap1 n (\i ->
    0.99 * vw[i] + ((1 - 0.99) * dw[i] * dw[i]))
  let m_hat = imap1 n (\i ->
    new_mw[i] / (1 - 0.85 ** ((nn64.fromi64 step) + 1)))
  let v_hat = imap1 n (\i ->
    new_vw[i] / (1 - (0.99 ** ((nn64.fromi64 step) + 1))))
  let new_w = imap1 n (\i ->
    w[i] - (lt_r * m_hat[i] / ((v_hat[i] ** 0.5) + 0.00000001)))
  in (new_w, new_mw, new_vw)

def adam_opt2 [n] [m] (w : [n][m]f64) (mw : [n][m]f64) (vw : [n][m]f64)
  (dw : [n][m]f64) (step : i64) (lt_r : f64):
  ([n][m]f64, [n][m]f64, [n][m]f64) =
  let new_mw = imap2 n m (\i j ->
    0.85 * mw[i][j] + ((1 - 0.85) * dw[i][j]))
  let new_vw = imap2 n m (\i j ->
    0.99 * vw[i][j] + ((1 - 0.99) * dw[i][j] * dw[i][j]))
  let m_hat = imap2 n m (\i j ->
    new_mw[i][j] / (1 - 0.85 ** ((nn64.fromi64 step) + 1)))
  let v_hat = imap2 n m (\i j ->
    new_vw[i][j] / (1 - (0.99 ** ((nn64.fromi64 step) + 1))))
  let new_w = imap2 n m (\i j ->
    w[i][j] - (lt_r * m_hat[i][j] / ((v_hat[i][j] ** 0.5) + 0.00000001)))
  in (new_w, new_mw, new_vw)

def adam_opt (p : params) (mp : params) (vp : params)
  (dp : params) (step : i64) steps :
  (params,  params,  params) =
  let lt_r = 0.01 * (1 - (nn64.fromi64 step) / (nn64.fromi64 steps))
  let (wt, mwt, vwt) =
    adam_opt2 p.wt mp.wt vp.wt dp.wt step lt_r
  let (wp, mwp, vwp) =
    adam_opt2 p.wp mp.wp vp.wp dp.wp step lt_r
  let (wqry, mwqry, vwqry) =
    adam_opt2 p.wqry mp.wqry vp.wqry dp.wqry step lt_r
  let (bqry, mbqry, vbqry) =
    adam_opt1 p.bqry mp.bqry vp.bqry dp.bqry step lt_r
  let (wkey, mwkey, vwkey) =
    adam_opt2 p.wkey mp.wkey vp.wkey dp.wkey step lt_r
  let (bkey, mbkey, vbkey) =
    adam_opt1 p.bkey mp.bkey vp.bkey dp.bkey step lt_r
  let (wval, mwval, vwval) =
    adam_opt2 p.wval mp.wval vp.wval dp.wval step lt_r
  let (bval, mbval, vbval) =
    adam_opt1 p.bval mp.bval vp.bval dp.bval step lt_r
  let (wo, mwo, vwo) =
    adam_opt2 p.wo mp.wo vp.wo dp.wo step lt_r
  let (bo, mbo, vbo) =
    adam_opt1 p.bo mp.bo vp.bo dp.bo step lt_r
  let (wu, mwu, vwu) =
    adam_opt2 p.wu mp.wu vp.wu dp.wu step lt_r
  let (bu, mbu, vbu) =
    adam_opt1 p.bu mp.bu vp.bu dp.bu step lt_r
  let (wd, mwd, vwd) =
    adam_opt2 p.wd mp.wd vp.wd dp.wd step lt_r
  let (bd, mbd, vbd) =
    adam_opt1 p.bd mp.bd vp.bd dp.bd step lt_r
  let (wc, mwc, vwc) =
    adam_opt2 p.wc mp.wc vp.wc dp.wc step lt_r
  let (bc, mbc, vbc) =
    adam_opt1 p.bc mp.bc vp.bc dp.bc step lt_r
  let p'  = to_params wt wp wqry bqry wkey bkey wval bval wo bo wu bu wd bd wc bc
  let mp' = to_params mwt mwp mwqry mbqry mwkey mbkey mwval mbval mwo mbo mwu mbu mwd mbd mwc mbc
  let vp' = to_params vwt vwp vwqry vbqry vwkey vbkey vwval vbval vwo vbo vwu vbu vwd vbd vwc vbc
  in (p', mp', vp')

def cal_step [bs] (p : params) (mp : params) (vp : params)
  (batch : [bs][sl]i64) (mask : [sl][sl]f64)
  (step : i64) steps :
  (params,  params,  params) =
  -- cal gradient
  let (dwt, dwp, dwqry, dbqry, dwkey, dbkey, dwval, dbval, dwo, dbo, dwu, dbu, dwd, dbd, dwc, dbc) =
    grad p batch mask
  let dp = to_params dwt dwp dwqry dbqry dwkey dbkey dwval dbval dwo dbo dwu dbu dwd dbd dwc dbc
  -- cal new model weights
  let (p', mp', vp') =
    adam_opt p mp vp dp step steps
  in (p', mp', vp')

entry train [bs] [steps] (p : params) (mp : params) (vp : params)
  (mask : [sl][sl]f64)
  (batches  : [steps][bs][sl]i64) =
  let (new_p, new_mp, new_vp) =
    loop (p', mp', vp') = (p, mp, vp)
    for step < steps do
      let batch = batches[step]
      let (p', mp', vp') = (cal_step p' mp' vp' batch mask step steps)
      in (p', mp', vp')
  in ((from_params new_p), (from_params new_mp), (from_params new_vp))

entry zero_params : params =
  let wt = imap2 vo ed (\_ _ -> 0)
  let wp = imap2 sl ed (\_ _ -> 0)
  let wqry = imap2 ed ed (\_ _ -> 0)
  let bqry = imap1 ed (\_ -> 0)
  let wkey = imap2 ed ed (\_ _ -> 0)
  let bkey = imap1 ed (\_ -> 0)
  let wval = imap2 ed ed (\_ _ -> 0)
  let bval = imap1 ed (\_ -> 0)
  let wo = imap2 ed ed (\_ _ -> 0)
  let bo = imap1 ed (\_ -> 0)
  let wu = imap2 fd ed (\_ _ -> 0)
  let bu = imap1 fd (\_ -> 0)
  let wd = imap2 ed fd (\_ _ -> 0)
  let bd = imap1 ed (\_ -> 0)
  let wc = imap2 vo ed (\_ _ -> 0)
  let bc = imap1 vo (\_ -> 0)
  in {wt, wp, wqry, bqry, wkey, bkey, wval, bval, wo, bo, wu, bu, wd, bd, wc, bc}