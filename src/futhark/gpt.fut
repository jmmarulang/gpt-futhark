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

(let x0 = (imap1 bs (\i5 -> (let x6 = (imap2 16 16 (\i19 i20 -> (wp[i19][i20] F.+ ws[i5][i19][i20])))
in (let x7 = (imap1 16 (\i21 -> (let x22 = (imap1 16 (\i26 -> (x6[i21][i26] F.* x6[i21][i26])))
in (let x23 = ((isum1 16 (\i27 -> x22[i27])) F./ fromi64 16)
in (let x24 = (F.sqrt (x23 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i25 -> (x6[i21][i25] F.* (one F./ x24)))))))))
in (let x8 = (imap1 16 (\i28 -> (imap1 16 (\i29 -> ((isum1 16 (\i30 -> (wqry[i29][i30] F.* x7[i28][i30]))) F.+ bqry[i29])))))
in (let x9 = (imap1 16 (\i31 -> (imap1 16 (\i32 -> ((isum1 16 (\i33 -> (wkey[i32][i33] F.* x7[i31][i33]))) F.+ bkey[i32])))))
in (let x10 = (imap1 16 (\i34 -> (imap1 16 (\i35 -> ((isum1 16 (\i36 -> (wval[i35][i36] F.* x7[i34][i36]))) F.+ bval[i35])))))
in (let x11 = (imap1 4 (\i37 -> (let x38 = (imap1 16 (\i40 -> (let x42 = (isoftmax1 16 (\i41 -> (((isum1 4 (\i44 -> (x8[i40][((i37 * 4) + i44)] F.* x9[i41][((i37 * 4) + i44)]))) F./ fromi64 2) F.+ mask[i40][i41])))
in (imap1 16 (\i43 -> x42[i43])))))
in (imap1 16 (\i39 -> (imap1 4 (\i45 -> (isum1 16 (\i46 -> (x38[i39][i46] F.* x10[i46][((i37 * 4) + i45)]))))))))))
in (let x12 = (imap1 16 (\i47 -> (imap1 16 (\i48 -> x11[(i48 / 4)][i47][(i48 % 4)]))))
in (let x13 = (imap1 16 (\i49 -> (imap1 16 (\i50 -> (x6[i49][i50] F.+ ((isum1 16 (\i51 -> (wo[i50][i51] F.* x12[i49][i51]))) F.+ bo[i50]))))))
in (let x14 = (imap1 16 (\i52 -> (let x53 = (imap1 16 (\i57 -> (x13[i52][i57] F.* x13[i52][i57])))
in (let x54 = ((isum1 16 (\i58 -> x53[i58])) F./ fromi64 16)
in (let x55 = (F.sqrt (x54 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i56 -> (x13[i52][i56] F.* (one F./ x55)))))))))
in (let x15 = (imap2 16 64 (\i59 i60 -> (F.max ((isum1 16 (\i61 -> (wu[i60][i61] F.* x14[i59][i61]))) F.+ bu[i60]) zero)))
in (let x16 = (imap1 16 (\i62 -> (imap1 16 (\i63 -> (x13[i62][i63] F.+ ((isum1 64 (\i64 -> (wd[i63][i64] F.* x15[i62][i64]))) F.+ bd[i63]))))))
in (let x17 = (imap1 16 (\i65 -> (let x66 = (imap1 16 (\i70 -> (x16[i65][i70] F.* x16[i65][i70])))
in (let x67 = ((isum1 16 (\i71 -> x66[i71])) F./ fromi64 16)
in (let x68 = (F.sqrt (x67 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i69 -> (x16[i65][i69] F.* (one F./ x68)))))))))
in (imap1 16 (\i18 -> (imap1 27 (\i72 -> ((isum1 16 (\i73 -> (wc[i72][i73] F.* x17[i18][i73]))) F.+ bc[i72])))))))))))))))))))
in (let x1 = (imap3 bs 16 27 (\i74 i75 i76 -> (target[i74][i75][i76] F.* (F.neg (F.log (let x78 = (isoftmax1 27 (\i77 -> x0[i74][i75][i77]))
in x78[i76]))))))
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
let x0 = (imap1 bs (\i1 -> (let x2 = (imap2 16 16 (\i15 i16 -> (wp[i15][i16] F.+ ws[i1][i15][i16])))
in (let x3 = (imap1 16 (\i17 -> (let x18 = ((isum1 16 (\i21 -> (x2[i17][i21] F.* x2[i17][i21]))) F./ fromi64 16)
in (let x19 = (F.sqrt (x18 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i20 -> (x2[i17][i20] F.* (one F./ x19))))))))
in (let x4 = (imap1 16 (\i22 -> (imap1 16 (\i23 -> ((isum1 16 (\i24 -> (wqry[i23][i24] F.* x3[i22][i24]))) F.+ bqry[i23])))))
in (let x5 = (imap1 16 (\i25 -> (imap1 16 (\i26 -> ((isum1 16 (\i27 -> (wkey[i26][i27] F.* x3[i25][i27]))) F.+ bkey[i26])))))
in (let x6 = (imap1 16 (\i28 -> (imap1 16 (\i29 -> ((isum1 16 (\i30 -> (wval[i29][i30] F.* x3[i28][i30]))) F.+ bval[i29])))))
in (let x7 = (imap1 4 (\i31 -> (let x32 = (imap1 16 (\i34 -> (let x36 = (isoftmax1 16 (\i35 -> (((isum1 4 (\i38 -> (x4[i34][((i31 * 4) + i38)] F.* x5[i35][((i31 * 4) + i38)]))) F./ fromi64 2) F.+ mask[i34][i35])))
in (imap1 16 (\i37 -> x36[i37])))))
in (imap1 16 (\i33 -> (imap1 4 (\i39 -> (isum1 16 (\i40 -> (x32[i33][i40] F.* x6[i40][((i31 * 4) + i39)]))))))))))
in (let x8 = (imap1 16 (\i41 -> (imap1 16 (\i42 -> x7[(i42 / 4)][i41][(i42 % 4)]))))
in (let x9 = (imap1 16 (\i43 -> (imap1 16 (\i44 -> (x2[i43][i44] F.+ ((isum1 16 (\i45 -> (wo[i44][i45] F.* x8[i43][i45]))) F.+ bo[i44]))))))
in (let x10 = (imap1 16 (\i46 -> (let x47 = ((isum1 16 (\i50 -> (x9[i46][i50] F.* x9[i46][i50]))) F./ fromi64 16)
in (let x48 = (F.sqrt (x47 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i49 -> (x9[i46][i49] F.* (one F./ x48))))))))
in (let x11 = (imap2 16 64 (\i51 i52 -> (F.max ((isum1 16 (\i53 -> (wu[i52][i53] F.* x10[i51][i53]))) F.+ bu[i52]) zero)))
in (let x12 = (imap1 16 (\i54 -> (imap1 16 (\i55 -> (x9[i54][i55] F.+ ((isum1 64 (\i56 -> (wd[i55][i56] F.* x11[i54][i56]))) F.+ bd[i55]))))))
in (let x13 = (imap1 16 (\i57 -> (let x58 = ((isum1 16 (\i61 -> (x12[i57][i61] F.* x12[i57][i61]))) F./ fromi64 16)
in (let x59 = (F.sqrt (x58 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i60 -> (x12[i57][i60] F.* (one F./ x59))))))))
in (imap1 16 (\i14 -> (imap1 27 (\i62 -> ((isum1 16 (\i63 -> (wc[i62][i63] F.* x13[i14][i63]))) F.+ bc[i62])))))))))))))))))))
let x64 = (imap3 bs 16 27 (\i65 i66 i67 -> (one F./ fromi64 (bs * 16))))
let x68 = (imap1 bs (\i69 -> (imap1 16 (\i70 -> (let x72 = (isoftmax1 27 (\i71 -> x0[i69][i70][i71]))
in (imap1 27 (\i73 -> x72[i73])))))))
let x74 = (imap1 bs (\i75 -> (imap1 16 (\i76 -> (imap1 27 (\i79 -> (F.neg ((target[i75][i76][i79] F.* x64[i75][i76][i79]) F.* (one F./ (let x78 = (isoftmax1 27 (\i77 -> x0[i75][i76][i77]))
in x78[i79]))))))))))
let x80 = (imap1 bs (\i81 -> (imap1 16 (\i82 -> (isum1 27 (\i83 -> (x74[i81][i82][i83] F.* x68[i81][i82][i83])))))))
let x84 = (imap1 bs (\i85 -> (imap1 16 (\i86 -> (imap1 27 (\i87 -> (x68[i85][i86][i87] F.* (x74[i85][i86][i87] F.+ (F.neg x80[i85][i86])))))))))
let x88 = (imap1 bs (\i89 -> (imap2 16 16 (\i90 i91 -> (wp[i90][i91] F.+ ws[i89][i90][i91])))))
let x92 = (imap1 bs (\i93 -> (imap1 16 (\i94 -> (let x95 = ((isum1 16 (\i98 -> (x88[i93][i94][i98] F.* x88[i93][i94][i98]))) F./ fromi64 16)
in (let x96 = (F.sqrt (x95 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i97 -> (x88[i93][i94][i97] F.* (one F./ x96))))))))))
let x99 = (imap1 bs (\i100 -> (imap1 16 (\i101 -> (imap1 16 (\i102 -> ((isum1 16 (\i103 -> (wqry[i102][i103] F.* x92[i100][i101][i103]))) F.+ bqry[i102])))))))
let x104 = (imap1 bs (\i105 -> (imap1 16 (\i106 -> (imap1 16 (\i107 -> ((isum1 16 (\i108 -> (wkey[i107][i108] F.* x92[i105][i106][i108]))) F.+ bkey[i107])))))))
let x109 = (imap1 bs (\i110 -> (imap1 16 (\i111 -> (imap1 16 (\i112 -> ((isum1 16 (\i113 -> (wval[i112][i113] F.* x92[i110][i111][i113]))) F.+ bval[i112])))))))
let x114 = (imap1 bs (\i115 -> (imap1 4 (\i116 -> (let x117 = (imap1 16 (\i119 -> (let x121 = (isoftmax1 16 (\i120 -> (((isum1 4 (\i123 -> (x99[i115][i119][((i116 * 4) + i123)] F.* x104[i115][i120][((i116 * 4) + i123)]))) F./ fromi64 2) F.+ mask[i119][i120])))
in (imap1 16 (\i122 -> x121[i122])))))
in (imap1 16 (\i118 -> (imap1 4 (\i124 -> (isum1 16 (\i125 -> (x117[i118][i125] F.* x109[i115][i125][((i116 * 4) + i124)]))))))))))))
let x126 = (imap1 bs (\i127 -> (imap1 16 (\i128 -> (imap1 16 (\i129 -> x114[i127][(i129 / 4)][i128][(i129 % 4)]))))))
let x130 = (imap1 bs (\i131 -> (imap1 16 (\i132 -> (imap1 16 (\i133 -> (x88[i131][i132][i133] F.+ ((isum1 16 (\i134 -> (wo[i133][i134] F.* x126[i131][i132][i134]))) F.+ bo[i133]))))))))
let x135 = (imap1 bs (\i136 -> (imap1 16 (\i137 -> (let x138 = ((isum1 16 (\i141 -> (x130[i136][i137][i141] F.* x130[i136][i137][i141]))) F./ fromi64 16)
in (let x139 = (F.sqrt (x138 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i140 -> (x130[i136][i137][i140] F.* (one F./ x139))))))))))
let x142 = (imap1 bs (\i143 -> (imap2 16 64 (\i144 i145 -> (F.max ((isum1 16 (\i146 -> (wu[i145][i146] F.* x135[i143][i144][i146]))) F.+ bu[i145]) zero)))))
let x147 = (imap1 bs (\i148 -> (imap1 16 (\i149 -> (imap1 16 (\i150 -> (x130[i148][i149][i150] F.+ ((isum1 64 (\i151 -> (wd[i150][i151] F.* x142[i148][i149][i151]))) F.+ bd[i150]))))))))
let x152 = (imap1 bs (\i153 -> (imap1 16 (\i154 -> (let x155 = ((isum1 16 (\i158 -> (x147[i153][i154][i158] F.* x147[i153][i154][i158]))) F./ fromi64 16)
in (let x156 = (F.sqrt (x155 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i157 -> (x147[i153][i154][i157] F.* (one F./ x156))))))))))
let x159 = (imap1 bs (\i160 -> (imap1 16 (\i161 -> (imap1 16 (\i162 -> (isum1 27 (\i163 -> (wc[i163][i162] F.* x84[i160][i161][i163])))))))))
let x164 = (imap1 bs (\i165 -> (imap1 16 (\i166 -> (imap1 16 (\i167 -> (x147[i165][i166][i167] F.* x147[i165][i166][i167])))))))
let x168 = (imap1 bs (\i169 -> (imap1 16 (\i170 -> ((isum1 16 (\i171 -> x164[i169][i170][i171])) F./ fromi64 16)))))
let x172 = (imap1 bs (\i173 -> (imap1 16 (\i174 -> (F.sqrt (x168[i173][i174] F.+ (one F./ fromi64 100000)))))))
let x175 = (imap1 bs (\i176 -> (imap1 16 (\i177 -> (F.neg ((one F./ x172[i176][i177]) F.* ((isum1 16 (\i178 -> (x147[i176][i177][i178] F.* x159[i176][i177][i178]))) F.* (one F./ x172[i176][i177]))))))))
let x179 = (imap1 bs (\i180 -> (imap1 16 (\i181 -> (x175[i180][i181] F.* (one F./ ((one F.+ one) F.* (F.sqrt (x168[i180][i181] F.+ (one F./ fromi64 100000))))))))))
let x182 = (imap1 bs (\i183 -> (imap1 16 (\i184 -> (imap1 16 (\i185 -> (x179[i183][i184] F./ fromi64 16)))))))
let x186 = (imap1 bs (\i187 -> (imap1 16 (\i188 -> (imap1 16 (\i189 -> (((x159[i187][i188][i189] F.* (one F./ x172[i187][i188])) F.+ (x147[i187][i188][i189] F.* x182[i187][i188][i189])) F.+ (x182[i187][i188][i189] F.* x147[i187][i188][i189]))))))))
let x190 = (imap1 bs (\i191 -> (imap1 16 (\i192 -> (imap1 64 (\i193 -> (isum1 16 (\i194 -> (wd[i194][i193] F.* x186[i191][i192][i194])))))))))
let x195 = (imap1 bs (\i196 -> (imap1 16 (\i197 -> (imap1 16 (\i198 -> (isum1 64 (\i199 -> (wu[i199][i198] F.* ((indicatorp ((isum1 16 (\i200 -> (wu[i199][i200] F.* x135[i196][i197][i200]))) F.+ bu[i199])) F.* x190[i196][i197][i199]))))))))))
let x201 = (imap1 bs (\i202 -> (imap1 16 (\i203 -> (imap1 16 (\i204 -> (x130[i202][i203][i204] F.* x130[i202][i203][i204])))))))
let x205 = (imap1 bs (\i206 -> (imap1 16 (\i207 -> ((isum1 16 (\i208 -> x201[i206][i207][i208])) F./ fromi64 16)))))
let x209 = (imap1 bs (\i210 -> (imap1 16 (\i211 -> (F.sqrt (x205[i210][i211] F.+ (one F./ fromi64 100000)))))))
let x212 = (imap1 bs (\i213 -> (imap1 16 (\i214 -> (F.neg ((one F./ x209[i213][i214]) F.* ((isum1 16 (\i215 -> (x130[i213][i214][i215] F.* x195[i213][i214][i215]))) F.* (one F./ x209[i213][i214]))))))))
let x216 = (imap1 bs (\i217 -> (imap1 16 (\i218 -> (x212[i217][i218] F.* (one F./ ((one F.+ one) F.* (F.sqrt (x205[i217][i218] F.+ (one F./ fromi64 100000))))))))))
let x219 = (imap1 bs (\i220 -> (imap1 16 (\i221 -> (imap1 16 (\i222 -> (x216[i220][i221] F./ fromi64 16)))))))
let x223 = (imap1 bs (\i224 -> (imap1 16 (\i225 -> (imap1 16 (\i226 -> (x186[i224][i225][i226] F.+ (((x195[i224][i225][i226] F.* (one F./ x209[i224][i225])) F.+ (x130[i224][i225][i226] F.* x219[i224][i225][i226])) F.+ (x219[i224][i225][i226] F.* x130[i224][i225][i226])))))))))
let x227 = (imap1 bs (\i228 -> (imap1 16 (\i229 -> (imap1 16 (\i230 -> (isum1 16 (\i231 -> (wo[i231][i230] F.* x223[i228][i229][i231])))))))))
let x232 = (imap1 bs (\i233 -> (imap1 4 (\i234 -> (imap1 16 (\i235 -> (imap1 4 (\i236 -> x227[i233][i235][((i234 * 4) + i236)]))))))))
let x237 = (imap1 bs (\i238 -> (imap1 4 (\i239 -> (imap1 16 (\i240 -> (let x242 = (isoftmax1 16 (\i241 -> (((isum1 4 (\i244 -> (x99[i238][i240][((i239 * 4) + i244)] F.* x104[i238][i241][((i239 * 4) + i244)]))) F./ fromi64 2) F.+ mask[i240][i241])))
in (imap1 16 (\i243 -> x242[i243])))))))))
let x245 = (imap1 bs (\i246 -> (imap1 4 (\i247 -> (imap1 16 (\i248 -> (imap1 16 (\i249 -> (isum1 4 (\i250 -> (x232[i246][i247][i248][i250] F.* x109[i246][i249][((i247 * 4) + i250)])))))))))))
let x251 = (imap1 bs (\i252 -> (imap1 4 (\i253 -> (imap1 16 (\i254 -> (imap1 16 (\i255 -> x245[i252][i253][i254][i255]))))))))
let x256 = (imap1 bs (\i257 -> (imap1 4 (\i258 -> (imap1 16 (\i259 -> (isum1 16 (\i260 -> (x251[i257][i258][i259][i260] F.* x237[i257][i258][i259][i260])))))))))
let x261 = (imap1 bs (\i262 -> (imap1 16 (\i263 -> (imap1 16 (\i264 -> (isum1 16 (\i265 -> (x237[i262][(i264 / 4)][i265][i263] F.* x232[i262][(i264 / 4)][i265][(i264 % 4)])))))))))
let x266 = (imap1 bs (\i267 -> (imap1 16 (\i268 -> (imap1 16 (\i269 -> (isum1 16 (\i270 -> (x99[i267][i270][(((i269 / 4) * 4) + (i269 % 4))] F.* ((x237[i267][(i269 / 4)][i270][i268] F.* (x251[i267][(i269 / 4)][i270][i268] F.+ (F.neg x256[i267][(i269 / 4)][i270]))) F./ fromi64 2))))))))))
let x271 = (imap1 bs (\i272 -> (imap1 16 (\i273 -> (imap1 16 (\i274 -> (isum1 16 (\i275 -> (((x237[i272][(i274 / 4)][i273][i275] F.* (x251[i272][(i274 / 4)][i273][i275] F.+ (F.neg x256[i272][(i274 / 4)][i273]))) F./ fromi64 2) F.* x104[i272][i275][(((i274 / 4) * 4) + (i274 % 4))])))))))))
let x276 = (imap1 bs (\i277 -> (imap1 16 (\i278 -> (imap1 16 (\i279 -> (((isum1 16 (\i280 -> (wval[i280][i279] F.* x261[i277][i278][i280]))) F.+ (isum1 16 (\i281 -> (wkey[i281][i279] F.* x266[i277][i278][i281])))) F.+ (isum1 16 (\i282 -> (wqry[i282][i279] F.* x271[i277][i278][i282]))))))))))
let x283 = (imap1 bs (\i284 -> (imap1 16 (\i285 -> (imap1 16 (\i286 -> (x88[i284][i285][i286] F.* x88[i284][i285][i286])))))))
let x287 = (imap1 bs (\i288 -> (imap1 16 (\i289 -> ((isum1 16 (\i290 -> x283[i288][i289][i290])) F./ fromi64 16)))))
let x291 = (imap1 bs (\i292 -> (imap1 16 (\i293 -> (F.sqrt (x287[i292][i293] F.+ (one F./ fromi64 100000)))))))
let x294 = (imap1 bs (\i295 -> (imap1 16 (\i296 -> (F.neg ((one F./ x291[i295][i296]) F.* ((isum1 16 (\i297 -> (x88[i295][i296][i297] F.* x276[i295][i296][i297]))) F.* (one F./ x291[i295][i296]))))))))
let x298 = (imap1 bs (\i299 -> (imap1 16 (\i300 -> (x294[i299][i300] F.* (one F./ ((one F.+ one) F.* (F.sqrt (x287[i299][i300] F.+ (one F./ fromi64 100000))))))))))
let x301 = (imap1 bs (\i302 -> (imap1 16 (\i303 -> (imap1 16 (\i304 -> (x298[i302][i303] F./ fromi64 16)))))))
let x305 = (imap1 bs (\i306 -> (imap1 16 (\i307 -> (imap1 16 (\i308 -> (x223[i306][i307][i308] F.+ (((x276[i306][i307][i308] F.* (one F./ x291[i306][i307])) F.+ (x88[i306][i307][i308] F.* x301[i306][i307][i308])) F.+ (x301[i306][i307][i308] F.* x88[i306][i307][i308])))))))))

let dwp = (imap2 16 16 (\i310 i311 -> (isum1 bs (\i309 -> x305[i309][i310][i311]))))
let dwqry = (imap1 16 (\i312 -> (imap1 16 (\i313 -> (isum1 bs (\i314 -> (isum1 16 (\i315 -> (x271[i314][i315][i312] F.* x92[i314][i315][i313])))))))))
let dwkey = (imap1 16 (\i316 -> (imap1 16 (\i317 -> (isum1 bs (\i318 -> (isum1 16 (\i319 -> (x266[i318][i319][i316] F.* x92[i318][i319][i317])))))))))
let dwval = (imap1 16 (\i320 -> (imap1 16 (\i321 -> (isum1 bs (\i322 -> (isum1 16 (\i323 -> (x261[i322][i323][i320] F.* x92[i322][i323][i321])))))))))
let dwo = (imap1 16 (\i324 -> (imap1 16 (\i325 -> (isum1 bs (\i326 -> (isum1 16 (\i327 -> (x223[i326][i327][i324] F.* x126[i326][i327][i325])))))))))
let dmask = (imap1 16 (\i328 -> (imap1 16 (\i331 -> (isum1 bs (\i329 -> (isum1 4 (\i330 -> (x237[i329][i330][i328][i331] F.* (x251[i329][i330][i328][i331] F.+ (F.neg x256[i329][i330][i328])))))))))))
let dwu = (imap1 64 (\i332 -> (imap1 16 (\i333 -> (isum1 bs (\i334 -> (isum1 16 (\i335 -> (((indicatorp ((isum1 16 (\i336 -> (wu[i332][i336] F.* x135[i334][i335][i336]))) F.+ bu[i332])) F.* x190[i334][i335][i332]) F.* x135[i334][i335][i333])))))))))
let dwd = (imap1 16 (\i337 -> (imap1 64 (\i338 -> (isum1 bs (\i339 -> (isum1 16 (\i340 -> (x186[i339][i340][i337] F.* x142[i339][i340][i338])))))))))
let dwc = (imap1 27 (\i341 -> (imap1 16 (\i342 -> (isum1 bs (\i343 -> (isum1 16 (\i344 -> (x84[i343][i344][i341] F.* x152[i343][i344][i342])))))))))
let dbqry = (imap1 16 (\i347 -> (isum1 bs (\i345 -> (isum1 16 (\i346 -> x271[i345][i346][i347]))))))
let dbkey = (imap1 16 (\i350 -> (isum1 bs (\i348 -> (isum1 16 (\i349 -> x266[i348][i349][i350]))))))
let dbval = (imap1 16 (\i353 -> (isum1 bs (\i351 -> (isum1 16 (\i352 -> x261[i351][i352][i353]))))))
let dbo = (imap1 16 (\i356 -> (isum1 bs (\i354 -> (isum1 16 (\i355 -> x223[i354][i355][i356]))))))
let dbu = (imap1 64 (\i359 -> (isum1 bs (\i357 -> (isum1 16 (\i358 -> ((indicatorp ((isum1 16 (\i360 -> (wu[i359][i360] F.* x135[i357][i358][i360]))) F.+ bu[i359])) F.* x190[i357][i358][i359])))))))
let dbd = (imap1 16 (\i363 -> (isum1 bs (\i361 -> (isum1 16 (\i362 -> x186[i361][i362][i363]))))))
let dbc = (imap1 27 (\i366 -> (isum1 bs (\i364 -> (isum1 16 (\i365 -> x84[i364][i365][i366]))))))
let dws = (imap1 bs (\i367 -> (imap2 16 16 (\i368 i369 -> x305[i367][i368][i369]))))
let dtarget = (imap3 bs 16 27 (\i370 i371 i372 -> (x64[i370][i371][i372] F.* (F.neg (F.log (let x374 = (isoftmax1 27 (\i373 -> x0[i370][i371][i373]))
in x374[i372]))))))

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