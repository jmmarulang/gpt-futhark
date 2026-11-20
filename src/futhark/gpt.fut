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
in (let x7 = (imap1 16 (\i21 -> (let x22 = (imap1 16 (\i27 -> (x6[i21][i27] F.+ (F.neg zero))))
in (let x23 = (imap1 16 (\i28 -> (x22[i28] F.* x22[i28])))
in (let x24 = ((isum1 16 (\i29 -> x23[i29])) F./ fromi64 16)
in (let x25 = (F.sqrt (x24 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i26 -> (x6[i21][i26] F.* (one F./ x25))))))))))
in (let x8 = (imap1 16 (\i30 -> (imap1 16 (\i31 -> ((isum1 16 (\i32 -> (wqry[i31][i32] F.* x7[i30][i32]))) F.+ bqry[i31])))))
in (let x9 = (imap1 16 (\i33 -> (imap1 16 (\i34 -> ((isum1 16 (\i35 -> (wkey[i34][i35] F.* x7[i33][i35]))) F.+ bkey[i34])))))
in (let x10 = (imap1 16 (\i36 -> (imap1 16 (\i37 -> ((isum1 16 (\i38 -> (wval[i37][i38] F.* x7[i36][i38]))) F.+ bval[i37])))))
in (let x11 = (imap1 4 (\i39 -> (let x40 = (imap1 16 (\i42 -> (let x44 = (isoftmax1 16 (\i43 -> (((isum1 4 (\i46 -> (x8[i42][((i39 * 4) + i46)] F.* x9[i43][((i39 * 4) + i46)]))) F./ fromi64 2) F.+ mask[i42][i43])))
in (imap1 16 (\i45 -> x44[i45])))))
in (imap1 16 (\i41 -> (imap1 4 (\i47 -> (isum1 16 (\i48 -> (x40[i41][i48] F.* x10[i48][((i39 * 4) + i47)]))))))))))
in (let x12 = (imap1 16 (\i49 -> (imap1 16 (\i50 -> x11[(i50 / 4)][i49][(i50 % 4)]))))
in (let x13 = (imap1 16 (\i51 -> (imap1 16 (\i52 -> (x6[i51][i52] F.+ ((isum1 16 (\i53 -> (wo[i52][i53] F.* x12[i51][i53]))) F.+ bo[i52]))))))
in (let x14 = (imap1 16 (\i54 -> (let x55 = (imap1 16 (\i60 -> (x13[i54][i60] F.+ (F.neg zero))))
in (let x56 = (imap1 16 (\i61 -> (x55[i61] F.* x55[i61])))
in (let x57 = ((isum1 16 (\i62 -> x56[i62])) F./ fromi64 16)
in (let x58 = (F.sqrt (x57 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i59 -> (x13[i54][i59] F.* (one F./ x58))))))))))
in (let x15 = (imap2 16 64 (\i63 i64 -> (F.max ((isum1 16 (\i65 -> (wu[i64][i65] F.* x14[i63][i65]))) F.+ bu[i64]) zero)))
in (let x16 = (imap1 16 (\i66 -> (imap1 16 (\i67 -> (x13[i66][i67] F.+ ((isum1 64 (\i68 -> (wd[i67][i68] F.* x15[i66][i68]))) F.+ bd[i67]))))))
in (let x17 = (imap1 16 (\i69 -> (let x70 = (imap1 16 (\i75 -> (x16[i69][i75] F.+ (F.neg zero))))
in (let x71 = (imap1 16 (\i76 -> (x70[i76] F.* x70[i76])))
in (let x72 = ((isum1 16 (\i77 -> x71[i77])) F./ fromi64 16)
in (let x73 = (F.sqrt (x72 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i74 -> (x16[i69][i74] F.* (one F./ x73))))))))))
in (imap1 16 (\i18 -> (imap1 27 (\i78 -> ((isum1 16 (\i79 -> (wc[i78][i79] F.* x17[i18][i79]))) F.+ bc[i78])))))))))))))))))))
in (let x1 = (imap3 bs 16 27 (\i80 i81 i82 -> (target[i80][i81][i82] F.* (F.neg (F.log (let x84 = (isoftmax1 27 (\i83 -> x0[i80][i81][i83]))
in x84[i82]))))))
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
in (let x3 = (imap1 16 (\i17 -> (let x18 = (imap1 16 (\i22 -> (x2[i17][i22] F.+ (F.neg zero))))
in (let x19 = ((isum1 16 (\i23 -> (x18[i23] F.* x18[i23]))) F./ fromi64 16)
in (let x20 = (F.sqrt (x19 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i21 -> (x2[i17][i21] F.* (one F./ x20)))))))))
in (let x4 = (imap1 16 (\i24 -> (imap1 16 (\i25 -> ((isum1 16 (\i26 -> (wqry[i25][i26] F.* x3[i24][i26]))) F.+ bqry[i25])))))
in (let x5 = (imap1 16 (\i27 -> (imap1 16 (\i28 -> ((isum1 16 (\i29 -> (wkey[i28][i29] F.* x3[i27][i29]))) F.+ bkey[i28])))))
in (let x6 = (imap1 16 (\i30 -> (imap1 16 (\i31 -> ((isum1 16 (\i32 -> (wval[i31][i32] F.* x3[i30][i32]))) F.+ bval[i31])))))
in (let x7 = (imap1 4 (\i33 -> (let x34 = (imap1 16 (\i36 -> (let x38 = (isoftmax1 16 (\i37 -> (((isum1 4 (\i40 -> (x4[i36][((i33 * 4) + i40)] F.* x5[i37][((i33 * 4) + i40)]))) F./ fromi64 2) F.+ mask[i36][i37])))
in (imap1 16 (\i39 -> x38[i39])))))
in (imap1 16 (\i35 -> (imap1 4 (\i41 -> (isum1 16 (\i42 -> (x34[i35][i42] F.* x6[i42][((i33 * 4) + i41)]))))))))))
in (let x8 = (imap1 16 (\i43 -> (imap1 16 (\i44 -> x7[(i44 / 4)][i43][(i44 % 4)]))))
in (let x9 = (imap1 16 (\i45 -> (imap1 16 (\i46 -> (x2[i45][i46] F.+ ((isum1 16 (\i47 -> (wo[i46][i47] F.* x8[i45][i47]))) F.+ bo[i46]))))))
in (let x10 = (imap1 16 (\i48 -> (let x49 = (imap1 16 (\i53 -> (x9[i48][i53] F.+ (F.neg zero))))
in (let x50 = ((isum1 16 (\i54 -> (x49[i54] F.* x49[i54]))) F./ fromi64 16)
in (let x51 = (F.sqrt (x50 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i52 -> (x9[i48][i52] F.* (one F./ x51)))))))))
in (let x11 = (imap2 16 64 (\i55 i56 -> (F.max ((isum1 16 (\i57 -> (wu[i56][i57] F.* x10[i55][i57]))) F.+ bu[i56]) zero)))
in (let x12 = (imap1 16 (\i58 -> (imap1 16 (\i59 -> (x9[i58][i59] F.+ ((isum1 64 (\i60 -> (wd[i59][i60] F.* x11[i58][i60]))) F.+ bd[i59]))))))
in (let x13 = (imap1 16 (\i61 -> (let x62 = (imap1 16 (\i66 -> (x12[i61][i66] F.+ (F.neg zero))))
in (let x63 = ((isum1 16 (\i67 -> (x62[i67] F.* x62[i67]))) F./ fromi64 16)
in (let x64 = (F.sqrt (x63 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i65 -> (x12[i61][i65] F.* (one F./ x64)))))))))
in (imap1 16 (\i14 -> (imap1 27 (\i68 -> ((isum1 16 (\i69 -> (wc[i68][i69] F.* x13[i14][i69]))) F.+ bc[i68])))))))))))))))))))
let x70 = (imap3 bs 16 27 (\i71 i72 i73 -> (one F./ fromi64 (bs * 16))))
let x74 = (imap1 bs (\i75 -> (imap1 16 (\i76 -> (let x78 = (isoftmax1 27 (\i77 -> x0[i75][i76][i77]))
in (imap1 27 (\i79 -> x78[i79])))))))
let x80 = (imap1 bs (\i81 -> (imap1 16 (\i82 -> (imap1 27 (\i85 -> (F.neg ((target[i81][i82][i85] F.* x70[i81][i82][i85]) F.* (one F./ (let x84 = (isoftmax1 27 (\i83 -> x0[i81][i82][i83]))
in x84[i85]))))))))))
let x86 = (imap1 bs (\i87 -> (imap1 16 (\i88 -> (isum1 27 (\i89 -> (x80[i87][i88][i89] F.* x74[i87][i88][i89])))))))
let x90 = (imap1 bs (\i91 -> (imap1 16 (\i92 -> (imap1 27 (\i93 -> (x74[i91][i92][i93] F.* (x80[i91][i92][i93] F.+ (F.neg x86[i91][i92])))))))))
let x94 = (imap1 bs (\i95 -> (imap2 16 16 (\i96 i97 -> (wp[i96][i97] F.+ ws[i95][i96][i97])))))
let x98 = (imap1 bs (\i99 -> (imap1 16 (\i100 -> (let x101 = (imap1 16 (\i105 -> (x94[i99][i100][i105] F.+ (F.neg zero))))
in (let x102 = ((isum1 16 (\i106 -> (x101[i106] F.* x101[i106]))) F./ fromi64 16)
in (let x103 = (F.sqrt (x102 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i104 -> (x94[i99][i100][i104] F.* (one F./ x103)))))))))))
let x107 = (imap1 bs (\i108 -> (imap1 16 (\i109 -> (imap1 16 (\i110 -> ((isum1 16 (\i111 -> (wqry[i110][i111] F.* x98[i108][i109][i111]))) F.+ bqry[i110])))))))
let x112 = (imap1 bs (\i113 -> (imap1 16 (\i114 -> (imap1 16 (\i115 -> ((isum1 16 (\i116 -> (wkey[i115][i116] F.* x98[i113][i114][i116]))) F.+ bkey[i115])))))))
let x117 = (imap1 bs (\i118 -> (imap1 16 (\i119 -> (imap1 16 (\i120 -> ((isum1 16 (\i121 -> (wval[i120][i121] F.* x98[i118][i119][i121]))) F.+ bval[i120])))))))
let x122 = (imap1 bs (\i123 -> (imap1 4 (\i124 -> (let x125 = (imap1 16 (\i127 -> (let x129 = (isoftmax1 16 (\i128 -> (((isum1 4 (\i131 -> (x107[i123][i127][((i124 * 4) + i131)] F.* x112[i123][i128][((i124 * 4) + i131)]))) F./ fromi64 2) F.+ mask[i127][i128])))
in (imap1 16 (\i130 -> x129[i130])))))
in (imap1 16 (\i126 -> (imap1 4 (\i132 -> (isum1 16 (\i133 -> (x125[i126][i133] F.* x117[i123][i133][((i124 * 4) + i132)]))))))))))))
let x134 = (imap1 bs (\i135 -> (imap1 16 (\i136 -> (imap1 16 (\i137 -> x122[i135][(i137 / 4)][i136][(i137 % 4)]))))))
let x138 = (imap1 bs (\i139 -> (imap1 16 (\i140 -> (imap1 16 (\i141 -> (x94[i139][i140][i141] F.+ ((isum1 16 (\i142 -> (wo[i141][i142] F.* x134[i139][i140][i142]))) F.+ bo[i141]))))))))
let x143 = (imap1 bs (\i144 -> (imap1 16 (\i145 -> (let x146 = (imap1 16 (\i150 -> (x138[i144][i145][i150] F.+ (F.neg zero))))
in (let x147 = ((isum1 16 (\i151 -> (x146[i151] F.* x146[i151]))) F./ fromi64 16)
in (let x148 = (F.sqrt (x147 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i149 -> (x138[i144][i145][i149] F.* (one F./ x148)))))))))))
let x152 = (imap1 bs (\i153 -> (imap2 16 64 (\i154 i155 -> (F.max ((isum1 16 (\i156 -> (wu[i155][i156] F.* x143[i153][i154][i156]))) F.+ bu[i155]) zero)))))
let x157 = (imap1 bs (\i158 -> (imap1 16 (\i159 -> (imap1 16 (\i160 -> (x138[i158][i159][i160] F.+ ((isum1 64 (\i161 -> (wd[i160][i161] F.* x152[i158][i159][i161]))) F.+ bd[i160]))))))))
let x162 = (imap1 bs (\i163 -> (imap1 16 (\i164 -> (let x165 = (imap1 16 (\i169 -> (x157[i163][i164][i169] F.+ (F.neg zero))))
in (let x166 = ((isum1 16 (\i170 -> (x165[i170] F.* x165[i170]))) F./ fromi64 16)
in (let x167 = (F.sqrt (x166 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i168 -> (x157[i163][i164][i168] F.* (one F./ x167)))))))))))
let x171 = (imap1 bs (\i172 -> (imap1 16 (\i173 -> (imap1 16 (\i174 -> (isum1 27 (\i175 -> (wc[i175][i174] F.* x90[i172][i173][i175])))))))))
let x176 = (imap1 bs (\i177 -> (imap1 16 (\i178 -> (imap1 16 (\i179 -> (x157[i177][i178][i179] F.+ (F.neg zero))))))))
let x180 = (imap1 bs (\i181 -> (imap1 16 (\i182 -> (imap1 16 (\i183 -> (x176[i181][i182][i183] F.* x176[i181][i182][i183])))))))
let x184 = (imap1 bs (\i185 -> (imap1 16 (\i186 -> ((isum1 16 (\i187 -> x180[i185][i186][i187])) F./ fromi64 16)))))
let x188 = (imap1 bs (\i189 -> (imap1 16 (\i190 -> (F.sqrt (x184[i189][i190] F.+ (one F./ fromi64 100000)))))))
let x191 = (imap1 bs (\i192 -> (imap1 16 (\i193 -> (F.neg ((one F./ x188[i192][i193]) F.* ((isum1 16 (\i194 -> (x157[i192][i193][i194] F.* x171[i192][i193][i194]))) F.* (one F./ x188[i192][i193]))))))))
let x195 = (imap1 bs (\i196 -> (imap1 16 (\i197 -> (x191[i196][i197] F.* (one F./ ((one F.+ one) F.* (F.sqrt (x184[i196][i197] F.+ (one F./ fromi64 100000))))))))))
let x198 = (imap1 bs (\i199 -> (imap1 16 (\i200 -> (imap1 16 (\i201 -> (x195[i199][i200] F./ fromi64 16)))))))
let x202 = (imap1 bs (\i203 -> (imap1 16 (\i204 -> (imap1 16 (\i205 -> ((x176[i203][i204][i205] F.* x198[i203][i204][i205]) F.+ (x198[i203][i204][i205] F.* x176[i203][i204][i205]))))))))
let x206 = (imap1 bs (\i207 -> (imap1 16 (\i208 -> (imap1 16 (\i209 -> ((x171[i207][i208][i209] F.* (one F./ x188[i207][i208])) F.+ x202[i207][i208][i209])))))))
let x210 = (imap1 bs (\i211 -> (imap1 16 (\i212 -> (imap1 64 (\i213 -> (isum1 16 (\i214 -> (wd[i214][i213] F.* x206[i211][i212][i214])))))))))
let x215 = (imap1 bs (\i216 -> (imap1 16 (\i217 -> (imap1 16 (\i218 -> (isum1 64 (\i219 -> (wu[i219][i218] F.* ((indicatorp ((isum1 16 (\i220 -> (wu[i219][i220] F.* x143[i216][i217][i220]))) F.+ bu[i219])) F.* x210[i216][i217][i219]))))))))))
let x221 = (imap1 bs (\i222 -> (imap1 16 (\i223 -> (imap1 16 (\i224 -> (x138[i222][i223][i224] F.+ (F.neg zero))))))))
let x225 = (imap1 bs (\i226 -> (imap1 16 (\i227 -> (imap1 16 (\i228 -> (x221[i226][i227][i228] F.* x221[i226][i227][i228])))))))
let x229 = (imap1 bs (\i230 -> (imap1 16 (\i231 -> ((isum1 16 (\i232 -> x225[i230][i231][i232])) F./ fromi64 16)))))
let x233 = (imap1 bs (\i234 -> (imap1 16 (\i235 -> (F.sqrt (x229[i234][i235] F.+ (one F./ fromi64 100000)))))))
let x236 = (imap1 bs (\i237 -> (imap1 16 (\i238 -> (F.neg ((one F./ x233[i237][i238]) F.* ((isum1 16 (\i239 -> (x138[i237][i238][i239] F.* x215[i237][i238][i239]))) F.* (one F./ x233[i237][i238]))))))))
let x240 = (imap1 bs (\i241 -> (imap1 16 (\i242 -> (x236[i241][i242] F.* (one F./ ((one F.+ one) F.* (F.sqrt (x229[i241][i242] F.+ (one F./ fromi64 100000))))))))))
let x243 = (imap1 bs (\i244 -> (imap1 16 (\i245 -> (imap1 16 (\i246 -> (x240[i244][i245] F./ fromi64 16)))))))
let x247 = (imap1 bs (\i248 -> (imap1 16 (\i249 -> (imap1 16 (\i250 -> ((x221[i248][i249][i250] F.* x243[i248][i249][i250]) F.+ (x243[i248][i249][i250] F.* x221[i248][i249][i250]))))))))
let x251 = (imap1 bs (\i252 -> (imap1 16 (\i253 -> (imap1 16 (\i254 -> (x206[i252][i253][i254] F.+ ((x215[i252][i253][i254] F.* (one F./ x233[i252][i253])) F.+ x247[i252][i253][i254]))))))))
let x255 = (imap1 bs (\i256 -> (imap1 16 (\i257 -> (imap1 16 (\i258 -> (isum1 16 (\i259 -> (wo[i259][i258] F.* x251[i256][i257][i259])))))))))
let x260 = (imap1 bs (\i261 -> (imap1 4 (\i262 -> (imap1 16 (\i263 -> (imap1 4 (\i264 -> x255[i261][i263][((i262 * 4) + i264)]))))))))
let x265 = (imap1 bs (\i266 -> (imap1 4 (\i267 -> (imap1 16 (\i268 -> (let x270 = (isoftmax1 16 (\i269 -> (((isum1 4 (\i272 -> (x107[i266][i268][((i267 * 4) + i272)] F.* x112[i266][i269][((i267 * 4) + i272)]))) F./ fromi64 2) F.+ mask[i268][i269])))
in (imap1 16 (\i271 -> x270[i271])))))))))
let x273 = (imap1 bs (\i274 -> (imap1 4 (\i275 -> (imap1 16 (\i276 -> (imap1 16 (\i277 -> (isum1 4 (\i278 -> (x260[i274][i275][i276][i278] F.* x117[i274][i277][((i275 * 4) + i278)])))))))))))
let x279 = (imap1 bs (\i280 -> (imap1 4 (\i281 -> (imap1 16 (\i282 -> (imap1 16 (\i283 -> x273[i280][i281][i282][i283]))))))))
let x284 = (imap1 bs (\i285 -> (imap1 4 (\i286 -> (imap1 16 (\i287 -> (isum1 16 (\i288 -> (x279[i285][i286][i287][i288] F.* x265[i285][i286][i287][i288])))))))))
let x289 = (imap1 bs (\i290 -> (imap1 16 (\i291 -> (imap1 16 (\i292 -> (isum1 16 (\i293 -> (x265[i290][(i292 / 4)][i293][i291] F.* x260[i290][(i292 / 4)][i293][(i292 % 4)])))))))))
let x294 = (imap1 bs (\i295 -> (imap1 16 (\i296 -> (imap1 16 (\i297 -> (isum1 16 (\i298 -> (x107[i295][i298][(((i297 / 4) * 4) + (i297 % 4))] F.* ((x265[i295][(i297 / 4)][i298][i296] F.* (x279[i295][(i297 / 4)][i298][i296] F.+ (F.neg x284[i295][(i297 / 4)][i298]))) F./ fromi64 2))))))))))
let x299 = (imap1 bs (\i300 -> (imap1 16 (\i301 -> (imap1 16 (\i302 -> (isum1 16 (\i303 -> (((x265[i300][(i302 / 4)][i301][i303] F.* (x279[i300][(i302 / 4)][i301][i303] F.+ (F.neg x284[i300][(i302 / 4)][i301]))) F./ fromi64 2) F.* x112[i300][i303][(((i302 / 4) * 4) + (i302 % 4))])))))))))
let x304 = (imap1 bs (\i305 -> (imap1 16 (\i306 -> (imap1 16 (\i307 -> (((isum1 16 (\i308 -> (wval[i308][i307] F.* x289[i305][i306][i308]))) F.+ (isum1 16 (\i309 -> (wkey[i309][i307] F.* x294[i305][i306][i309])))) F.+ (isum1 16 (\i310 -> (wqry[i310][i307] F.* x299[i305][i306][i310]))))))))))
let x311 = (imap1 bs (\i312 -> (imap1 16 (\i313 -> (imap1 16 (\i314 -> (x94[i312][i313][i314] F.+ (F.neg zero))))))))
let x315 = (imap1 bs (\i316 -> (imap1 16 (\i317 -> (imap1 16 (\i318 -> (x311[i316][i317][i318] F.* x311[i316][i317][i318])))))))
let x319 = (imap1 bs (\i320 -> (imap1 16 (\i321 -> ((isum1 16 (\i322 -> x315[i320][i321][i322])) F./ fromi64 16)))))
let x323 = (imap1 bs (\i324 -> (imap1 16 (\i325 -> (F.sqrt (x319[i324][i325] F.+ (one F./ fromi64 100000)))))))
let x326 = (imap1 bs (\i327 -> (imap1 16 (\i328 -> (F.neg ((one F./ x323[i327][i328]) F.* ((isum1 16 (\i329 -> (x94[i327][i328][i329] F.* x304[i327][i328][i329]))) F.* (one F./ x323[i327][i328]))))))))
let x330 = (imap1 bs (\i331 -> (imap1 16 (\i332 -> (x326[i331][i332] F.* (one F./ ((one F.+ one) F.* (F.sqrt (x319[i331][i332] F.+ (one F./ fromi64 100000))))))))))
let x333 = (imap1 bs (\i334 -> (imap1 16 (\i335 -> (imap1 16 (\i336 -> (x330[i334][i335] F./ fromi64 16)))))))
let x337 = (imap1 bs (\i338 -> (imap1 16 (\i339 -> (imap1 16 (\i340 -> ((x311[i338][i339][i340] F.* x333[i338][i339][i340]) F.+ (x333[i338][i339][i340] F.* x311[i338][i339][i340]))))))))
let x341 = (imap1 bs (\i342 -> (imap1 16 (\i343 -> (imap1 16 (\i344 -> (x251[i342][i343][i344] F.+ ((x304[i342][i343][i344] F.* (one F./ x323[i342][i343])) F.+ x337[i342][i343][i344]))))))))

let dwp = (imap2 16 16 (\i346 i347 -> (isum1 bs (\i345 -> x341[i345][i346][i347]))))
let dwqry = (imap1 16 (\i348 -> (imap1 16 (\i349 -> (isum1 bs (\i350 -> (isum1 16 (\i351 -> (x299[i350][i351][i348] F.* x98[i350][i351][i349])))))))))
let dwkey = (imap1 16 (\i352 -> (imap1 16 (\i353 -> (isum1 bs (\i354 -> (isum1 16 (\i355 -> (x294[i354][i355][i352] F.* x98[i354][i355][i353])))))))))
let dwval = (imap1 16 (\i356 -> (imap1 16 (\i357 -> (isum1 bs (\i358 -> (isum1 16 (\i359 -> (x289[i358][i359][i356] F.* x98[i358][i359][i357])))))))))
let dwo = (imap1 16 (\i360 -> (imap1 16 (\i361 -> (isum1 bs (\i362 -> (isum1 16 (\i363 -> (x251[i362][i363][i360] F.* x134[i362][i363][i361])))))))))
let dmask = (imap1 16 (\i364 -> (imap1 16 (\i367 -> (isum1 bs (\i365 -> (isum1 4 (\i366 -> (x265[i365][i366][i364][i367] F.* (x279[i365][i366][i364][i367] F.+ (F.neg x284[i365][i366][i364])))))))))))
let dwu = (imap1 64 (\i368 -> (imap1 16 (\i369 -> (isum1 bs (\i370 -> (isum1 16 (\i371 -> (((indicatorp ((isum1 16 (\i372 -> (wu[i368][i372] F.* x143[i370][i371][i372]))) F.+ bu[i368])) F.* x210[i370][i371][i368]) F.* x143[i370][i371][i369])))))))))
let dwd = (imap1 16 (\i373 -> (imap1 64 (\i374 -> (isum1 bs (\i375 -> (isum1 16 (\i376 -> (x206[i375][i376][i373] F.* x152[i375][i376][i374])))))))))
let dwc = (imap1 27 (\i377 -> (imap1 16 (\i378 -> (isum1 bs (\i379 -> (isum1 16 (\i380 -> (x90[i379][i380][i377] F.* x162[i379][i380][i378])))))))))
let dbqry = (imap1 16 (\i383 -> (isum1 bs (\i381 -> (isum1 16 (\i382 -> x299[i381][i382][i383]))))))
let dbkey = (imap1 16 (\i386 -> (isum1 bs (\i384 -> (isum1 16 (\i385 -> x294[i384][i385][i386]))))))
let dbval = (imap1 16 (\i389 -> (isum1 bs (\i387 -> (isum1 16 (\i388 -> x289[i387][i388][i389]))))))
let dbo = (imap1 16 (\i392 -> (isum1 bs (\i390 -> (isum1 16 (\i391 -> x251[i390][i391][i392]))))))
let dbu = (imap1 64 (\i395 -> (isum1 bs (\i393 -> (isum1 16 (\i394 -> ((indicatorp ((isum1 16 (\i396 -> (wu[i395][i396] F.* x143[i393][i394][i396]))) F.+ bu[i395])) F.* x210[i393][i394][i395])))))))
let dbd = (imap1 16 (\i399 -> (isum1 bs (\i397 -> (isum1 16 (\i398 -> x206[i397][i398][i399]))))))
let dbc = (imap1 27 (\i402 -> (isum1 bs (\i400 -> (isum1 16 (\i401 -> x90[i400][i401][i402]))))))
let dws = (imap1 bs (\i403 -> (imap2 16 16 (\i404 i405 -> x341[i403][i404][i405]))))
let dtarget = (imap3 bs 16 27 (\i406 i407 i408 -> (x70[i406][i407][i408] F.* (F.neg (F.log (let x410 = (isoftmax1 27 (\i409 -> x0[i406][i407][i409]))
in x410[i408]))))))

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