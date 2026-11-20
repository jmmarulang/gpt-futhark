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
  (wa: [16]real) (ba: [16]real)
  (wqry: [16][16]real) (bqry: [16]real)
  (wkey: [16][16]real) (bkey: [16]real)
  (wval: [16][16]real) (bval: [16]real)
  (wo: [16][16]real) (bo: [16]real)
  (mask: [16][16]real)
  (wm: [16]real) (bm: [16]real)
  (wu: [64][16]real) (bu: [64]real)
  (wd: [16][64]real) (bd: [16]real)
  (wf: [16]real) (bf: [16]real)
  (wc: [27][16]real) (bc: [27]real)
  (ws: [bs][16][16]real)
  : [bs][16][27]real =
#[unsafe] --DANGER: Is this correct?
(imap1 bs (\i0 -> (let x1 = (imap2 16 16 (\i14 i15 -> (wp[i14][i15] F.+ ws[i0][i14][i15])))
in (let x2 = (imap1 16 (\i16 -> (let x17 = (imap1 16 (\i23 -> ((isum1 16 (\i24 -> x1[i16][i24])) F./ fromi64 16)))
in (let x18 = (imap1 16 (\i25 -> (x1[i16][i25] F.+ (F.neg x17[i25]))))
in (let x19 = (imap1 16 (\i26 -> (x18[i26] F.* x18[i26])))
in (let x20 = ((isum1 16 (\i27 -> x19[i27])) F./ fromi64 16)
in (let x21 = (F.sqrt (x20 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i22 -> (((x18[i22] F.* (one F./ x21)) F.* wa[i22]) F.+ ba[i22]))))))))))
in (let x3 = (imap1 16 (\i28 -> (imap1 16 (\i29 -> ((isum1 16 (\i30 -> (wqry[i29][i30] F.* x2[i28][i30]))) F.+ bqry[i29])))))
in (let x4 = (imap1 16 (\i31 -> (imap1 16 (\i32 -> ((isum1 16 (\i33 -> (wkey[i32][i33] F.* x2[i31][i33]))) F.+ bkey[i32])))))
in (let x5 = (imap1 16 (\i34 -> (imap1 16 (\i35 -> ((isum1 16 (\i36 -> (wval[i35][i36] F.* x2[i34][i36]))) F.+ bval[i35])))))
in (let x6 = (imap1 4 (\i37 -> (let x38 = (imap1 16 (\i40 -> (let x42 = (isoftmax1 16 (\i41 -> (((isum1 4 (\i44 -> (x3[i40][((i37 * 4) + i44)] F.* x4[i41][((i37 * 4) + i44)]))) F./ fromi64 2) F.+ mask[i40][i41])))
in (imap1 16 (\i43 -> x42[i43])))))
in (imap1 16 (\i39 -> (imap1 4 (\i45 -> (isum1 16 (\i46 -> (x38[i39][i46] F.* x5[i46][((i37 * 4) + i45)]))))))))))
in (let x7 = (imap1 16 (\i47 -> (imap1 16 (\i48 -> x6[(i48 / 4)][i47][(i48 % 4)]))))
in (let x8 = (imap1 16 (\i49 -> (imap1 16 (\i50 -> (x1[i49][i50] F.+ ((isum1 16 (\i51 -> (wo[i50][i51] F.* x7[i49][i51]))) F.+ bo[i50]))))))
in (let x9 = (imap1 16 (\i52 -> (let x53 = (imap1 16 (\i59 -> ((isum1 16 (\i60 -> x8[i52][i60])) F./ fromi64 16)))
in (let x54 = (imap1 16 (\i61 -> (x8[i52][i61] F.+ (F.neg x53[i61]))))
in (let x55 = (imap1 16 (\i62 -> (x54[i62] F.* x54[i62])))
in (let x56 = ((isum1 16 (\i63 -> x55[i63])) F./ fromi64 16)
in (let x57 = (F.sqrt (x56 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i58 -> (((x54[i58] F.* (one F./ x57)) F.* wm[i58]) F.+ bm[i58]))))))))))
in (let x10 = (imap2 16 64 (\i64 i65 -> (F.max ((isum1 16 (\i66 -> (wu[i65][i66] F.* x9[i64][i66]))) F.+ bu[i65]) zero)))
in (let x11 = (imap1 16 (\i67 -> (imap1 16 (\i68 -> (x8[i67][i68] F.+ ((isum1 64 (\i69 -> (wd[i68][i69] F.* x10[i67][i69]))) F.+ bd[i68]))))))
in (let x12 = (imap1 16 (\i70 -> (let x71 = (imap1 16 (\i77 -> ((isum1 16 (\i78 -> x11[i70][i78])) F./ fromi64 16)))
in (let x72 = (imap1 16 (\i79 -> (x11[i70][i79] F.+ (F.neg x71[i79]))))
in (let x73 = (imap1 16 (\i80 -> (x72[i80] F.* x72[i80])))
in (let x74 = ((isum1 16 (\i81 -> x73[i81])) F./ fromi64 16)
in (let x75 = (F.sqrt (x74 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i76 -> (((x72[i76] F.* (one F./ x75)) F.* wf[i76]) F.+ bf[i76]))))))))))
in (imap1 16 (\i13 -> (imap1 27 (\i82 -> ((isum1 16 (\i83 -> (wc[i82][i83] F.* x12[i13][i83]))) F.+ bc[i82])))))))))))))))))))

def cal_loss [bs]
  (wp: [16][16]real)
  (wa: [16]real) (ba: [16]real)
  (wqry: [16][16]real) (bqry: [16]real)
  (wkey: [16][16]real) (bkey: [16]real)
  (wval: [16][16]real) (bval: [16]real)
  (wo: [16][16]real) (bo: [16]real)
  (mask: [16][16]real)
  (wm: [16]real) (bm: [16]real)
  (wu: [64][16]real) (bu: [64]real)
  (wd: [16][64]real) (bd: [16]real)
  (wf: [16]real) (bf: [16]real)
  (wc: [27][16]real) (bc: [27]real)
  (ws: [bs][16][16]real)
  (target: [bs][16][27]real)
  : real =

(let x0 = (imap1 bs (\i5 -> (let x6 = (imap2 16 16 (\i19 i20 -> (wp[i19][i20] F.+ ws[i5][i19][i20])))
in (let x7 = (imap1 16 (\i21 -> (let x22 = (imap1 16 (\i28 -> ((isum1 16 (\i29 -> x6[i21][i29])) F./ fromi64 16)))
in (let x23 = (imap1 16 (\i30 -> (x6[i21][i30] F.+ (F.neg x22[i30]))))
in (let x24 = (imap1 16 (\i31 -> (x23[i31] F.* x23[i31])))
in (let x25 = ((isum1 16 (\i32 -> x24[i32])) F./ fromi64 16)
in (let x26 = (F.sqrt (x25 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i27 -> (((x23[i27] F.* (one F./ x26)) F.* wa[i27]) F.+ ba[i27]))))))))))
in (let x8 = (imap1 16 (\i33 -> (imap1 16 (\i34 -> ((isum1 16 (\i35 -> (wqry[i34][i35] F.* x7[i33][i35]))) F.+ bqry[i34])))))
in (let x9 = (imap1 16 (\i36 -> (imap1 16 (\i37 -> ((isum1 16 (\i38 -> (wkey[i37][i38] F.* x7[i36][i38]))) F.+ bkey[i37])))))
in (let x10 = (imap1 16 (\i39 -> (imap1 16 (\i40 -> ((isum1 16 (\i41 -> (wval[i40][i41] F.* x7[i39][i41]))) F.+ bval[i40])))))
in (let x11 = (imap1 4 (\i42 -> (let x43 = (imap1 16 (\i45 -> (let x47 = (isoftmax1 16 (\i46 -> (((isum1 4 (\i49 -> (x8[i45][((i42 * 4) + i49)] F.* x9[i46][((i42 * 4) + i49)]))) F./ fromi64 2) F.+ mask[i45][i46])))
in (imap1 16 (\i48 -> x47[i48])))))
in (imap1 16 (\i44 -> (imap1 4 (\i50 -> (isum1 16 (\i51 -> (x43[i44][i51] F.* x10[i51][((i42 * 4) + i50)]))))))))))
in (let x12 = (imap1 16 (\i52 -> (imap1 16 (\i53 -> x11[(i53 / 4)][i52][(i53 % 4)]))))
in (let x13 = (imap1 16 (\i54 -> (imap1 16 (\i55 -> (x6[i54][i55] F.+ ((isum1 16 (\i56 -> (wo[i55][i56] F.* x12[i54][i56]))) F.+ bo[i55]))))))
in (let x14 = (imap1 16 (\i57 -> (let x58 = (imap1 16 (\i64 -> ((isum1 16 (\i65 -> x13[i57][i65])) F./ fromi64 16)))
in (let x59 = (imap1 16 (\i66 -> (x13[i57][i66] F.+ (F.neg x58[i66]))))
in (let x60 = (imap1 16 (\i67 -> (x59[i67] F.* x59[i67])))
in (let x61 = ((isum1 16 (\i68 -> x60[i68])) F./ fromi64 16)
in (let x62 = (F.sqrt (x61 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i63 -> (((x59[i63] F.* (one F./ x62)) F.* wm[i63]) F.+ bm[i63]))))))))))
in (let x15 = (imap2 16 64 (\i69 i70 -> (F.max ((isum1 16 (\i71 -> (wu[i70][i71] F.* x14[i69][i71]))) F.+ bu[i70]) zero)))
in (let x16 = (imap1 16 (\i72 -> (imap1 16 (\i73 -> (x13[i72][i73] F.+ ((isum1 64 (\i74 -> (wd[i73][i74] F.* x15[i72][i74]))) F.+ bd[i73]))))))
in (let x17 = (imap1 16 (\i75 -> (let x76 = (imap1 16 (\i82 -> ((isum1 16 (\i83 -> x16[i75][i83])) F./ fromi64 16)))
in (let x77 = (imap1 16 (\i84 -> (x16[i75][i84] F.+ (F.neg x76[i84]))))
in (let x78 = (imap1 16 (\i85 -> (x77[i85] F.* x77[i85])))
in (let x79 = ((isum1 16 (\i86 -> x78[i86])) F./ fromi64 16)
in (let x80 = (F.sqrt (x79 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i81 -> (((x77[i81] F.* (one F./ x80)) F.* wf[i81]) F.+ bf[i81]))))))))))
in (imap1 16 (\i18 -> (imap1 27 (\i87 -> ((isum1 16 (\i88 -> (wc[i87][i88] F.* x17[i18][i88]))) F.+ bc[i87])))))))))))))))))))
in (let x1 = (imap3 bs 16 27 (\i89 i90 i91 -> (target[i89][i90][i91] F.* (F.neg (F.log (let x93 = (isoftmax1 27 (\i92 -> x0[i89][i90][i92]))
in x93[i91]))))))
in ((isum3 bs 16 27 (\i2 i3 i4 -> x1[i2][i3][i4])) F./ fromi64 (bs * 16))))

def grad [bs]
  (wp: [16][16]real)
  (wa: [16]real) (ba: [16]real)
  (wqry: [16][16]real) (bqry: [16]real)
  (wkey: [16][16]real) (bkey: [16]real)
  (wval: [16][16]real) (bval: [16]real)
  (wo: [16][16]real) (bo: [16]real)
  (mask: [16][16]real)
  (wm: [16]real) (bm: [16]real)
  (wu: [64][16]real) (bu: [64]real)
  (wd: [16][64]real) (bd: [16]real)
  (wf: [16]real) (bf: [16]real)
  (wc: [27][16]real) (bc: [27]real)
  (ws: [bs][16][16]real)
  (target: [bs][16][27]real) :
  (
  [16][16]real,            -- position embedding
  [16]real, [16]real,      -- att normalization
  [16][16]real, [16]real,  -- query weights
  [16][16]real, [16]real,  -- key weights
  [16][16]real, [16]real,  -- val weights
  [16][16]real, [16]real,  -- projection weights
  [16]real, [16]real,      -- mlp normalization
  [64][16]real, [64]real,  -- mpl up projection weights
  [16][64]real, [16]real,  -- mlp down projection weights
  [16]real, [16]real,      -- final normalization
  [27][16]real, [27]real,  -- vocabulary projection weights
  [bs][16][16]real         -- ws
  ) =
let x0 = (imap1 bs (\i1 -> (let x2 = (imap2 16 16 (\i15 i16 -> (wp[i15][i16] F.+ ws[i1][i15][i16])))
in (let x3 = (imap1 16 (\i17 -> (let x18 = (imap1 16 (\i23 -> ((isum1 16 (\i24 -> x2[i17][i24])) F./ fromi64 16)))
in (let x19 = (imap1 16 (\i25 -> (x2[i17][i25] F.+ (F.neg x18[i25]))))
in (let x20 = ((isum1 16 (\i26 -> (x19[i26] F.* x19[i26]))) F./ fromi64 16)
in (let x21 = (F.sqrt (x20 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i22 -> (((x19[i22] F.* (one F./ x21)) F.* wa[i22]) F.+ ba[i22])))))))))
in (let x4 = (imap1 16 (\i27 -> (imap1 16 (\i28 -> ((isum1 16 (\i29 -> (wqry[i28][i29] F.* x3[i27][i29]))) F.+ bqry[i28])))))
in (let x5 = (imap1 16 (\i30 -> (imap1 16 (\i31 -> ((isum1 16 (\i32 -> (wkey[i31][i32] F.* x3[i30][i32]))) F.+ bkey[i31])))))
in (let x6 = (imap1 16 (\i33 -> (imap1 16 (\i34 -> ((isum1 16 (\i35 -> (wval[i34][i35] F.* x3[i33][i35]))) F.+ bval[i34])))))
in (let x7 = (imap1 4 (\i36 -> (let x37 = (imap1 16 (\i39 -> (let x41 = (isoftmax1 16 (\i40 -> (((isum1 4 (\i43 -> (x4[i39][((i36 * 4) + i43)] F.* x5[i40][((i36 * 4) + i43)]))) F./ fromi64 2) F.+ mask[i39][i40])))
in (imap1 16 (\i42 -> x41[i42])))))
in (imap1 16 (\i38 -> (imap1 4 (\i44 -> (isum1 16 (\i45 -> (x37[i38][i45] F.* x6[i45][((i36 * 4) + i44)]))))))))))
in (let x8 = (imap1 16 (\i46 -> (imap1 16 (\i47 -> x7[(i47 / 4)][i46][(i47 % 4)]))))
in (let x9 = (imap1 16 (\i48 -> (imap1 16 (\i49 -> (x2[i48][i49] F.+ ((isum1 16 (\i50 -> (wo[i49][i50] F.* x8[i48][i50]))) F.+ bo[i49]))))))
in (let x10 = (imap1 16 (\i51 -> (let x52 = (imap1 16 (\i57 -> ((isum1 16 (\i58 -> x9[i51][i58])) F./ fromi64 16)))
in (let x53 = (imap1 16 (\i59 -> (x9[i51][i59] F.+ (F.neg x52[i59]))))
in (let x54 = ((isum1 16 (\i60 -> (x53[i60] F.* x53[i60]))) F./ fromi64 16)
in (let x55 = (F.sqrt (x54 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i56 -> (((x53[i56] F.* (one F./ x55)) F.* wm[i56]) F.+ bm[i56])))))))))
in (let x11 = (imap2 16 64 (\i61 i62 -> (F.max ((isum1 16 (\i63 -> (wu[i62][i63] F.* x10[i61][i63]))) F.+ bu[i62]) zero)))
in (let x12 = (imap1 16 (\i64 -> (imap1 16 (\i65 -> (x9[i64][i65] F.+ ((isum1 64 (\i66 -> (wd[i65][i66] F.* x11[i64][i66]))) F.+ bd[i65]))))))
in (let x13 = (imap1 16 (\i67 -> (let x68 = (imap1 16 (\i73 -> ((isum1 16 (\i74 -> x12[i67][i74])) F./ fromi64 16)))
in (let x69 = (imap1 16 (\i75 -> (x12[i67][i75] F.+ (F.neg x68[i75]))))
in (let x70 = ((isum1 16 (\i76 -> (x69[i76] F.* x69[i76]))) F./ fromi64 16)
in (let x71 = (F.sqrt (x70 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i72 -> (((x69[i72] F.* (one F./ x71)) F.* wf[i72]) F.+ bf[i72])))))))))
in (imap1 16 (\i14 -> (imap1 27 (\i77 -> ((isum1 16 (\i78 -> (wc[i77][i78] F.* x13[i14][i78]))) F.+ bc[i77])))))))))))))))))))
let x79 = (imap3 bs 16 27 (\i80 i81 i82 -> (one F./ fromi64 (bs * 16))))
let x83 = (imap1 bs (\i84 -> (imap1 16 (\i85 -> (let x87 = (isoftmax1 27 (\i86 -> x0[i84][i85][i86]))
in (imap1 27 (\i88 -> x87[i88])))))))
let x89 = (imap1 bs (\i90 -> (imap1 16 (\i91 -> (imap1 27 (\i94 -> (F.neg ((target[i90][i91][i94] F.* x79[i90][i91][i94]) F.* (one F./ (let x93 = (isoftmax1 27 (\i92 -> x0[i90][i91][i92]))
in x93[i94]))))))))))
let x95 = (imap1 bs (\i96 -> (imap1 16 (\i97 -> (isum1 27 (\i98 -> (x89[i96][i97][i98] F.* x83[i96][i97][i98])))))))
let x99 = (imap1 bs (\i100 -> (imap1 16 (\i101 -> (imap1 27 (\i102 -> (x83[i100][i101][i102] F.* (x89[i100][i101][i102] F.+ (F.neg x95[i100][i101])))))))))
let x103 = (imap1 bs (\i104 -> (imap2 16 16 (\i105 i106 -> (wp[i105][i106] F.+ ws[i104][i105][i106])))))
let x107 = (imap1 bs (\i108 -> (imap1 16 (\i109 -> (let x110 = (imap1 16 (\i115 -> ((isum1 16 (\i116 -> x103[i108][i109][i116])) F./ fromi64 16)))
in (let x111 = (imap1 16 (\i117 -> (x103[i108][i109][i117] F.+ (F.neg x110[i117]))))
in (let x112 = ((isum1 16 (\i118 -> (x111[i118] F.* x111[i118]))) F./ fromi64 16)
in (let x113 = (F.sqrt (x112 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i114 -> (((x111[i114] F.* (one F./ x113)) F.* wa[i114]) F.+ ba[i114])))))))))))
let x119 = (imap1 bs (\i120 -> (imap1 16 (\i121 -> (imap1 16 (\i122 -> ((isum1 16 (\i123 -> (wqry[i122][i123] F.* x107[i120][i121][i123]))) F.+ bqry[i122])))))))
let x124 = (imap1 bs (\i125 -> (imap1 16 (\i126 -> (imap1 16 (\i127 -> ((isum1 16 (\i128 -> (wkey[i127][i128] F.* x107[i125][i126][i128]))) F.+ bkey[i127])))))))
let x129 = (imap1 bs (\i130 -> (imap1 16 (\i131 -> (imap1 16 (\i132 -> ((isum1 16 (\i133 -> (wval[i132][i133] F.* x107[i130][i131][i133]))) F.+ bval[i132])))))))
let x134 = (imap1 bs (\i135 -> (imap1 4 (\i136 -> (let x137 = (imap1 16 (\i139 -> (let x141 = (isoftmax1 16 (\i140 -> (((isum1 4 (\i143 -> (x119[i135][i139][((i136 * 4) + i143)] F.* x124[i135][i140][((i136 * 4) + i143)]))) F./ fromi64 2) F.+ mask[i139][i140])))
in (imap1 16 (\i142 -> x141[i142])))))
in (imap1 16 (\i138 -> (imap1 4 (\i144 -> (isum1 16 (\i145 -> (x137[i138][i145] F.* x129[i135][i145][((i136 * 4) + i144)]))))))))))))
let x146 = (imap1 bs (\i147 -> (imap1 16 (\i148 -> (imap1 16 (\i149 -> x134[i147][(i149 / 4)][i148][(i149 % 4)]))))))
let x150 = (imap1 bs (\i151 -> (imap1 16 (\i152 -> (imap1 16 (\i153 -> (x103[i151][i152][i153] F.+ ((isum1 16 (\i154 -> (wo[i153][i154] F.* x146[i151][i152][i154]))) F.+ bo[i153]))))))))
let x155 = (imap1 bs (\i156 -> (imap1 16 (\i157 -> (let x158 = (imap1 16 (\i163 -> ((isum1 16 (\i164 -> x150[i156][i157][i164])) F./ fromi64 16)))
in (let x159 = (imap1 16 (\i165 -> (x150[i156][i157][i165] F.+ (F.neg x158[i165]))))
in (let x160 = ((isum1 16 (\i166 -> (x159[i166] F.* x159[i166]))) F./ fromi64 16)
in (let x161 = (F.sqrt (x160 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i162 -> (((x159[i162] F.* (one F./ x161)) F.* wm[i162]) F.+ bm[i162])))))))))))
let x167 = (imap1 bs (\i168 -> (imap2 16 64 (\i169 i170 -> (F.max ((isum1 16 (\i171 -> (wu[i170][i171] F.* x155[i168][i169][i171]))) F.+ bu[i170]) zero)))))
let x172 = (imap1 bs (\i173 -> (imap1 16 (\i174 -> (imap1 16 (\i175 -> (x150[i173][i174][i175] F.+ ((isum1 64 (\i176 -> (wd[i175][i176] F.* x167[i173][i174][i176]))) F.+ bd[i175]))))))))
let x177 = (imap1 bs (\i178 -> (imap1 16 (\i179 -> (let x180 = (imap1 16 (\i185 -> ((isum1 16 (\i186 -> x172[i178][i179][i186])) F./ fromi64 16)))
in (let x181 = (imap1 16 (\i187 -> (x172[i178][i179][i187] F.+ (F.neg x180[i187]))))
in (let x182 = ((isum1 16 (\i188 -> (x181[i188] F.* x181[i188]))) F./ fromi64 16)
in (let x183 = (F.sqrt (x182 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i184 -> (((x181[i184] F.* (one F./ x183)) F.* wf[i184]) F.+ bf[i184])))))))))))
let x189 = (imap1 bs (\i190 -> (imap1 16 (\i191 -> (imap1 16 (\i192 -> (isum1 27 (\i193 -> (wc[i193][i192] F.* x99[i190][i191][i193])))))))))
let x194 = (imap1 bs (\i195 -> (imap1 16 (\i196 -> (imap1 16 (\i197 -> ((isum1 16 (\i198 -> x172[i195][i196][i198])) F./ fromi64 16)))))))
let x199 = (imap1 bs (\i200 -> (imap1 16 (\i201 -> (imap1 16 (\i202 -> (x172[i200][i201][i202] F.+ (F.neg x194[i200][i201][i202]))))))))
let x203 = (imap1 bs (\i204 -> (imap1 16 (\i205 -> (imap1 16 (\i206 -> (x199[i204][i205][i206] F.* x199[i204][i205][i206])))))))
let x207 = (imap1 bs (\i208 -> (imap1 16 (\i209 -> ((isum1 16 (\i210 -> x203[i208][i209][i210])) F./ fromi64 16)))))
let x211 = (imap1 bs (\i212 -> (imap1 16 (\i213 -> (F.sqrt (x207[i212][i213] F.+ (one F./ fromi64 100000)))))))
let x214 = (imap1 bs (\i215 -> (imap1 16 (\i216 -> (F.neg ((one F./ x211[i215][i216]) F.* ((isum1 16 (\i217 -> (x199[i215][i216][i217] F.* (x189[i215][i216][i217] F.* wf[i217])))) F.* (one F./ x211[i215][i216]))))))))
let x218 = (imap1 bs (\i219 -> (imap1 16 (\i220 -> (x214[i219][i220] F.* (one F./ ((one F.+ one) F.* (F.sqrt (x207[i219][i220] F.+ (one F./ fromi64 100000))))))))))
let x221 = (imap1 bs (\i222 -> (imap1 16 (\i223 -> (imap1 16 (\i224 -> (x218[i222][i223] F./ fromi64 16)))))))
let x225 = (imap1 bs (\i226 -> (imap1 16 (\i227 -> (imap1 16 (\i228 -> ((((x189[i226][i227][i228] F.* wf[i228]) F.* (one F./ x211[i226][i227])) F.+ (x199[i226][i227][i228] F.* x221[i226][i227][i228])) F.+ (x221[i226][i227][i228] F.* x199[i226][i227][i228]))))))))
let x229 = (imap1 bs (\i230 -> (imap1 16 (\i231 -> (imap1 16 (\i232 -> (F.neg x225[i230][i231][i232])))))))
let x233 = (imap1 bs (\i234 -> (imap1 16 (\i235 -> (imap1 16 (\i236 -> (x225[i234][i235][i236] F.+ (isum1 16 (\i237 -> (x229[i234][i235][i237] F./ fromi64 16))))))))))
let x238 = (imap1 bs (\i239 -> (imap1 16 (\i240 -> (imap1 64 (\i241 -> (isum1 16 (\i242 -> (wd[i242][i241] F.* x233[i239][i240][i242])))))))))
let x243 = (imap1 bs (\i244 -> (imap1 16 (\i245 -> (imap1 16 (\i246 -> (isum1 64 (\i247 -> (wu[i247][i246] F.* ((indicatorp ((isum1 16 (\i248 -> (wu[i247][i248] F.* x155[i244][i245][i248]))) F.+ bu[i247])) F.* x238[i244][i245][i247]))))))))))
let x249 = (imap1 bs (\i250 -> (imap1 16 (\i251 -> (imap1 16 (\i252 -> ((isum1 16 (\i253 -> x150[i250][i251][i253])) F./ fromi64 16)))))))
let x254 = (imap1 bs (\i255 -> (imap1 16 (\i256 -> (imap1 16 (\i257 -> (x150[i255][i256][i257] F.+ (F.neg x249[i255][i256][i257]))))))))
let x258 = (imap1 bs (\i259 -> (imap1 16 (\i260 -> (imap1 16 (\i261 -> (x254[i259][i260][i261] F.* x254[i259][i260][i261])))))))
let x262 = (imap1 bs (\i263 -> (imap1 16 (\i264 -> ((isum1 16 (\i265 -> x258[i263][i264][i265])) F./ fromi64 16)))))
let x266 = (imap1 bs (\i267 -> (imap1 16 (\i268 -> (F.sqrt (x262[i267][i268] F.+ (one F./ fromi64 100000)))))))
let x269 = (imap1 bs (\i270 -> (imap1 16 (\i271 -> (F.neg ((one F./ x266[i270][i271]) F.* ((isum1 16 (\i272 -> (x254[i270][i271][i272] F.* (x243[i270][i271][i272] F.* wm[i272])))) F.* (one F./ x266[i270][i271]))))))))
let x273 = (imap1 bs (\i274 -> (imap1 16 (\i275 -> (x269[i274][i275] F.* (one F./ ((one F.+ one) F.* (F.sqrt (x262[i274][i275] F.+ (one F./ fromi64 100000))))))))))
let x276 = (imap1 bs (\i277 -> (imap1 16 (\i278 -> (imap1 16 (\i279 -> (x273[i277][i278] F./ fromi64 16)))))))
let x280 = (imap1 bs (\i281 -> (imap1 16 (\i282 -> (imap1 16 (\i283 -> ((((x243[i281][i282][i283] F.* wm[i283]) F.* (one F./ x266[i281][i282])) F.+ (x254[i281][i282][i283] F.* x276[i281][i282][i283])) F.+ (x276[i281][i282][i283] F.* x254[i281][i282][i283]))))))))
let x284 = (imap1 bs (\i285 -> (imap1 16 (\i286 -> (imap1 16 (\i287 -> (F.neg x280[i285][i286][i287])))))))
let x288 = (imap1 bs (\i289 -> (imap1 16 (\i290 -> (imap1 16 (\i291 -> (x233[i289][i290][i291] F.+ (x280[i289][i290][i291] F.+ (isum1 16 (\i292 -> (x284[i289][i290][i292] F./ fromi64 16)))))))))))
let x293 = (imap1 bs (\i294 -> (imap1 16 (\i295 -> (imap1 16 (\i296 -> (isum1 16 (\i297 -> (wo[i297][i296] F.* x288[i294][i295][i297])))))))))
let x298 = (imap1 bs (\i299 -> (imap1 4 (\i300 -> (imap1 16 (\i301 -> (imap1 4 (\i302 -> x293[i299][i301][((i300 * 4) + i302)]))))))))
let x303 = (imap1 bs (\i304 -> (imap1 4 (\i305 -> (imap1 16 (\i306 -> (let x308 = (isoftmax1 16 (\i307 -> (((isum1 4 (\i310 -> (x119[i304][i306][((i305 * 4) + i310)] F.* x124[i304][i307][((i305 * 4) + i310)]))) F./ fromi64 2) F.+ mask[i306][i307])))
in (imap1 16 (\i309 -> x308[i309])))))))))
let x311 = (imap1 bs (\i312 -> (imap1 4 (\i313 -> (imap1 16 (\i314 -> (imap1 16 (\i315 -> (isum1 4 (\i316 -> (x298[i312][i313][i314][i316] F.* x129[i312][i315][((i313 * 4) + i316)])))))))))))
let x317 = (imap1 bs (\i318 -> (imap1 4 (\i319 -> (imap1 16 (\i320 -> (imap1 16 (\i321 -> x311[i318][i319][i320][i321]))))))))
let x322 = (imap1 bs (\i323 -> (imap1 4 (\i324 -> (imap1 16 (\i325 -> (isum1 16 (\i326 -> (x317[i323][i324][i325][i326] F.* x303[i323][i324][i325][i326])))))))))
let x327 = (imap1 bs (\i328 -> (imap1 16 (\i329 -> (imap1 16 (\i330 -> (isum1 16 (\i331 -> (x303[i328][(i330 / 4)][i331][i329] F.* x298[i328][(i330 / 4)][i331][(i330 % 4)])))))))))
let x332 = (imap1 bs (\i333 -> (imap1 16 (\i334 -> (imap1 16 (\i335 -> (isum1 16 (\i336 -> (x119[i333][i336][(((i335 / 4) * 4) + (i335 % 4))] F.* ((x303[i333][(i335 / 4)][i336][i334] F.* (x317[i333][(i335 / 4)][i336][i334] F.+ (F.neg x322[i333][(i335 / 4)][i336]))) F./ fromi64 2))))))))))
let x337 = (imap1 bs (\i338 -> (imap1 16 (\i339 -> (imap1 16 (\i340 -> (isum1 16 (\i341 -> (((x303[i338][(i340 / 4)][i339][i341] F.* (x317[i338][(i340 / 4)][i339][i341] F.+ (F.neg x322[i338][(i340 / 4)][i339]))) F./ fromi64 2) F.* x124[i338][i341][(((i340 / 4) * 4) + (i340 % 4))])))))))))
let x342 = (imap1 bs (\i343 -> (imap1 16 (\i344 -> (imap1 16 (\i345 -> (((isum1 16 (\i346 -> (wval[i346][i345] F.* x327[i343][i344][i346]))) F.+ (isum1 16 (\i347 -> (wkey[i347][i345] F.* x332[i343][i344][i347])))) F.+ (isum1 16 (\i348 -> (wqry[i348][i345] F.* x337[i343][i344][i348]))))))))))
let x349 = (imap1 bs (\i350 -> (imap1 16 (\i351 -> (imap1 16 (\i352 -> ((isum1 16 (\i353 -> x103[i350][i351][i353])) F./ fromi64 16)))))))
let x354 = (imap1 bs (\i355 -> (imap1 16 (\i356 -> (imap1 16 (\i357 -> (x103[i355][i356][i357] F.+ (F.neg x349[i355][i356][i357]))))))))
let x358 = (imap1 bs (\i359 -> (imap1 16 (\i360 -> (imap1 16 (\i361 -> (x354[i359][i360][i361] F.* x354[i359][i360][i361])))))))
let x362 = (imap1 bs (\i363 -> (imap1 16 (\i364 -> ((isum1 16 (\i365 -> x358[i363][i364][i365])) F./ fromi64 16)))))
let x366 = (imap1 bs (\i367 -> (imap1 16 (\i368 -> (F.sqrt (x362[i367][i368] F.+ (one F./ fromi64 100000)))))))
let x369 = (imap1 bs (\i370 -> (imap1 16 (\i371 -> (F.neg ((one F./ x366[i370][i371]) F.* ((isum1 16 (\i372 -> (x354[i370][i371][i372] F.* (x342[i370][i371][i372] F.* wa[i372])))) F.* (one F./ x366[i370][i371]))))))))
let x373 = (imap1 bs (\i374 -> (imap1 16 (\i375 -> (x369[i374][i375] F.* (one F./ ((one F.+ one) F.* (F.sqrt (x362[i374][i375] F.+ (one F./ fromi64 100000))))))))))
let x376 = (imap1 bs (\i377 -> (imap1 16 (\i378 -> (imap1 16 (\i379 -> (x373[i377][i378] F./ fromi64 16)))))))
let x380 = (imap1 bs (\i381 -> (imap1 16 (\i382 -> (imap1 16 (\i383 -> ((((x342[i381][i382][i383] F.* wa[i383]) F.* (one F./ x366[i381][i382])) F.+ (x354[i381][i382][i383] F.* x376[i381][i382][i383])) F.+ (x376[i381][i382][i383] F.* x354[i381][i382][i383]))))))))
let x384 = (imap1 bs (\i385 -> (imap1 16 (\i386 -> (imap1 16 (\i387 -> (F.neg x380[i385][i386][i387])))))))
let x388 = (imap1 bs (\i389 -> (imap1 16 (\i390 -> (imap1 16 (\i391 -> (x288[i389][i390][i391] F.+ (x380[i389][i390][i391] F.+ (isum1 16 (\i392 -> (x384[i389][i390][i392] F./ fromi64 16)))))))))))

let dwp = (imap2 16 16 (\i394 i395 -> (isum1 bs (\i393 -> x388[i393][i394][i395]))))
let dwa = (imap1 16 (\i396 -> (isum1 bs (\i397 -> (isum1 16 (\i398 -> ((x354[i397][i398][i396] F.* (one F./ x366[i397][i398])) F.* x342[i397][i398][i396])))))))
let dba = (imap1 16 (\i401 -> (isum1 bs (\i399 -> (isum1 16 (\i400 -> x342[i399][i400][i401]))))))
let dwqry = (imap1 16 (\i402 -> (imap1 16 (\i403 -> (isum1 bs (\i404 -> (isum1 16 (\i405 -> (x337[i404][i405][i402] F.* x107[i404][i405][i403])))))))))
let dwkey = (imap1 16 (\i406 -> (imap1 16 (\i407 -> (isum1 bs (\i408 -> (isum1 16 (\i409 -> (x332[i408][i409][i406] F.* x107[i408][i409][i407])))))))))
let dwval = (imap1 16 (\i410 -> (imap1 16 (\i411 -> (isum1 bs (\i412 -> (isum1 16 (\i413 -> (x327[i412][i413][i410] F.* x107[i412][i413][i411])))))))))
let dwo = (imap1 16 (\i414 -> (imap1 16 (\i415 -> (isum1 bs (\i416 -> (isum1 16 (\i417 -> (x288[i416][i417][i414] F.* x146[i416][i417][i415])))))))))
let dbqry = (imap1 16 (\i420 -> (isum1 bs (\i418 -> (isum1 16 (\i419 -> x337[i418][i419][i420]))))))
let dbkey = (imap1 16 (\i423 -> (isum1 bs (\i421 -> (isum1 16 (\i422 -> x332[i421][i422][i423]))))))
let dbval = (imap1 16 (\i426 -> (isum1 bs (\i424 -> (isum1 16 (\i425 -> x327[i424][i425][i426]))))))
let dbo = (imap1 16 (\i429 -> (isum1 bs (\i427 -> (isum1 16 (\i428 -> x288[i427][i428][i429]))))))
-- let dmask = (imap1 16 (\i430 -> (imap1 16 (\i433 -> (isum1 bs (\i431 -> (isum1 4 (\i432 -> (x303[i431][i432][i430][i433] F.* (x317[i431][i432][i430][i433] F.+ (F.neg x322[i431][i432][i430])))))))))))
let dwm = (imap1 16 (\i434 -> (isum1 bs (\i435 -> (isum1 16 (\i436 -> ((x254[i435][i436][i434] F.* (one F./ x266[i435][i436])) F.* x243[i435][i436][i434])))))))
let dbm = (imap1 16 (\i439 -> (isum1 bs (\i437 -> (isum1 16 (\i438 -> x243[i437][i438][i439]))))))
let dwu = (imap1 64 (\i440 -> (imap1 16 (\i441 -> (isum1 bs (\i442 -> (isum1 16 (\i443 -> (((indicatorp ((isum1 16 (\i444 -> (wu[i440][i444] F.* x155[i442][i443][i444]))) F.+ bu[i440])) F.* x238[i442][i443][i440]) F.* x155[i442][i443][i441])))))))))
let dwd = (imap1 16 (\i445 -> (imap1 64 (\i446 -> (isum1 bs (\i447 -> (isum1 16 (\i448 -> (x233[i447][i448][i445] F.* x167[i447][i448][i446])))))))))
let dbu = (imap1 64 (\i451 -> (isum1 bs (\i449 -> (isum1 16 (\i450 -> ((indicatorp ((isum1 16 (\i452 -> (wu[i451][i452] F.* x155[i449][i450][i452]))) F.+ bu[i451])) F.* x238[i449][i450][i451])))))))
let dbd = (imap1 16 (\i455 -> (isum1 bs (\i453 -> (isum1 16 (\i454 -> x233[i453][i454][i455]))))))
let dwf = (imap1 16 (\i456 -> (isum1 bs (\i457 -> (isum1 16 (\i458 -> ((x199[i457][i458][i456] F.* (one F./ x211[i457][i458])) F.* x189[i457][i458][i456])))))))
let dbf = (imap1 16 (\i461 -> (isum1 bs (\i459 -> (isum1 16 (\i460 -> x189[i459][i460][i461]))))))
let dwc = (imap1 27 (\i462 -> (imap1 16 (\i463 -> (isum1 bs (\i464 -> (isum1 16 (\i465 -> (x99[i464][i465][i462] F.* x177[i464][i465][i463])))))))))
let dbc = (imap1 27 (\i468 -> (isum1 bs (\i466 -> (isum1 16 (\i467 -> x99[i466][i467][i468]))))))
let dws = (imap1 bs (\i469 -> (imap2 16 16 (\i470 i471 -> x388[i469][i470][i471]))))
-- let dtarget = (imap3 bs 16 27 (\i472 i473 i474 -> (x79[i472][i473][i474] F.* (F.neg (F.log (let x476 = (isoftmax1 27 (\i475 -> x0[i472][i473][i475]))
-- in x476[i474]))))))

in (dwp, dwa, dba, dwqry, dbqry, dwkey, dbkey, dwval, dbval, dwo, dbo, dwm, dbm, dwu, dbu, dwd, dbd, dwf, dbf, dwc, dbc, dws)
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
  wa   : [ed]f64    , ba   : [ed]f64,    -- attention normalization
  wqry : [ed][ed]f64, bqry : [ed]f64,    -- query weights
  wkey : [ed][ed]f64, bkey : [ed]f64,    -- key weights
  wval : [ed][ed]f64, bval : [ed]f64,    -- value weights
  wo   : [ed][ed]f64, bo   : [ed]f64,    -- output weights
  wm   : [ed]f64    , bm   : [ed]f64,    -- MLP normalization
  wu   : [fd][ed]f64, bu   : [fd]f64,    -- MLP up-projection
  wd   : [ed][fd]f64, bd   : [ed]f64,    -- MLP down-projection
  wf   : [ed]f64    , bf   : [ed]f64,    -- final normalization
  wc   : [vo][ed]f64, bc   : [vo]f64     -- output projection
  }

entry to_params
    (wt: [vo][ed]f64)
    (wp: [sl][ed]f64)
    (wa: [ed]f64) (ba: [ed]f64)
    (wqry: [ed][ed]f64) (bqry: [ed]f64)
    (wkey: [ed][ed]f64) (bkey: [ed]f64)
    (wval: [ed][ed]f64) (bval: [ed]f64)
    (wo: [ed][ed]f64) (bo: [ed]f64)
    (wm: [ed]f64) (bm: [ed]f64)
    (wu: [fd][ed]f64) (bu: [fd]f64)
    (wd: [ed][fd]f64) (bd: [ed]f64)
    (wf: [ed]f64) (bf: [ed]f64)
    (wc: [vo][ed]f64) (bc: [vo]f64) : params =
  {wt, wp, wa, ba, wqry, bqry, wkey, bkey, wval, bval, wo, bo, wm, bm, wu, bu, wd, bd, wf, bf, wc, bc}

def from_params (p : params) :
  (
  [vo][ed]f64, -- token embeddings
  [sl][ed]f64, -- position embeddings
  [ed]f64, [ed]f64, -- attention normalization
  [ed][ed]f64, [ed]f64, -- query weights
  [ed][ed]f64, [ed]f64, -- key weights
  [ed][ed]f64, [ed]f64, -- value weights
  [ed][ed]f64, [ed]f64, -- output weights
  [ed]f64, [ed]f64, -- MLP normalization
  [fd][ed]f64, [fd]f64, -- MLP up-projection
  [ed][fd]f64, [ed]f64, -- MLP down-projection
  [ed]f64, [ed]f64, -- final normalization
  [vo][ed]f64, [vo]f64  -- output projection
  ) =
  let {wt, wp, wa, ba, wqry, bqry, wkey, bkey, wval, bval, wo, bo, wm, bm, wu, bu, wd, bd, wf, bf, wc, bc} = p
  in (wt, wp, wa, ba, wqry, bqry, wkey, bkey, wval, bval, wo, bo, wm, bm, wu, bu, wd, bd, wf, bf, wc, bc)

entry forward [bs] (p : params) (tokens : [bs][sl]i64) (mask : [sl][sl]f64) : [bs][sl][vo]f64 =
   let {wt, wp, wa, ba, wqry, bqry, wkey, bkey, wval, bval, wo, bo, wm, bm, wu, bu, wd, bd, wf, bf, wc, bc} = p
   let ws = (imap3 bs sl ed (\i j k -> wt[tokens[i][j]][k]))
   in (nn64.forward_seq
    (wp:> [16][16]f64)
    (wa:> [16]f64) (ba:> [16]f64)
    (wqry:> [16][16]f64) (bqry:> [16]f64)
    (wkey:> [16][16]f64) (bkey:> [16]f64)
    (wval:> [16][16]f64) (bval:> [16]f64)
    (wo:> [16][16]f64) (bo:> [16]f64)
    (mask :> [16][16]f64)
    (wm:> [16]f64) (bm:> [16]f64)
    (wu:> [64][16]f64) (bu:> [64]f64)
    (wd:> [16][64]f64) (bd:> [16]f64)
    (wf:> [16]f64) (bf:> [16]f64)
    (wc:> [27][16]f64) (bc:> [27]f64)
    (ws :> [bs][16][16]f64)
      :> [bs][sl][vo]f64)

entry cal_target [bs] (tokens : [bs][sl]i64) : [bs][sl]i64 =
  imap2 bs sl (\i j -> if (j < sl - 1) then tokens[i][j + 1] else vo)

entry cal_target_mask [bs] (n : i64) (target : [bs][sl]i64) : [bs][sl][vo]f64 =
  imap3 bs sl vo (\i j k -> (if ((j < (n - 1)) && (target[i][j] == k)) then 1 else 0))

entry loss [bs] (p : params) (tokens : [bs][sl]i64) (mask : [sl][sl]f64) : f64 =
   let {wt, wp, wa, ba, wqry, bqry, wkey, bkey, wval, bval, wo, bo, wm, bm, wu, bu, wd, bd, wf, bf, wc, bc} = p
   let target = cal_target_mask sl (cal_target tokens)
   let ws = (imap3 bs sl ed (\i j k -> wt[tokens[i][j]][k]))
   in (nn64.cal_loss
    (wp:> [16][16]f64)
    (wa:> [16]f64) (ba:> [16]f64)
    (wqry:> [16][16]f64) (bqry:> [16]f64)
    (wkey:> [16][16]f64) (bkey:> [16]f64)
    (wval:> [16][16]f64) (bval:> [16]f64)
    (wo:> [16][16]f64) (bo:> [16]f64)
    (mask :> [16][16]f64)
    (wm:> [16]f64) (bm:> [16]f64)
    (wu:> [64][16]f64) (bu:> [64]f64)
    (wd:> [16][64]f64) (bd:> [16]f64)
    (wf:> [16]f64) (bf:> [16]f64)
    (wc:> [27][16]f64) (bc:> [27]f64)
    (ws :> [bs][16][16]f64)
    (target :> [bs][16][27]f64)
              :> f64)

def grad [bs] (p : params) (tokens : [bs][sl]i64) (mask : [sl][sl]f64) :
        (
        [vo][ed]f64,
        [sl][ed]f64,
        [ed]f64, [ed]f64,
        [ed][ed]f64, [ed]f64,
        [ed][ed]f64, [ed]f64,
        [ed][ed]f64, [ed]f64,
        [ed][ed]f64, [ed]f64,
        [ed]f64, [ed]f64,
        [fd][ed]f64, [fd]f64,
        [ed][fd]f64, [ed]f64,
        [ed]f64, [ed]f64,
        [vo][ed]f64, [vo]f64
        ) =
   let {wt, wp, wa, ba, wqry, bqry, wkey, bkey, wval, bval, wo, bo, wm, bm, wu, bu, wd, bd, wf, bf, wc, bc} = p
   -- cal targets
   let target = cal_target_mask sl (cal_target tokens)
   -- cal voc embedding
   let ws = (imap3 bs sl ed (\i j k -> wt[tokens[i][j]][k]))
   -- cal gradient
   let (dwp, dwa, dba, dwqry, dbqry, dwkey, dbkey, dwval, dbval, dwo, dbo, dwm, dbm, dwu, dbu, dwd, dbd, dwf, dbf, dwc, dbc, dws) =
    (nn64.grad
(wp:> [16][16]f64)
    (wa:> [16]f64) (ba:> [16]f64)
    (wqry:> [16][16]f64) (bqry:> [16]f64)
    (wkey:> [16][16]f64) (bkey:> [16]f64)
    (wval:> [16][16]f64) (bval:> [16]f64)
    (wo:> [16][16]f64) (bo:> [16]f64)
    (mask :> [16][16]f64)
    (wm:> [16]f64) (bm:> [16]f64)
    (wu:> [64][16]f64) (bu:> [64]f64)
    (wd:> [16][64]f64) (bd:> [16]f64)
    (wf:> [16]f64) (bf:> [16]f64)
    (wc:> [27][16]f64) (bc:> [27]f64)
    (ws :> [bs][16][16]f64)
    (target :> [bs][16][27]f64)
                :>
    (
    [sl][ed]f64,
    [ed]f64, [ed]f64,
    [ed][ed]f64, [ed]f64,
    [ed][ed]f64, [ed]f64,
    [ed][ed]f64, [ed]f64,
    [ed][ed]f64, [ed]f64,
    [ed]f64, [ed]f64,
    [fd][ed]f64, [fd]f64,
    [ed][fd]f64, [ed]f64,
    [ed]f64, [ed]f64,
    [vo][ed]f64, [vo]f64,
    [bs][sl][ed]f64
    ))
   let dwt = (imap2 vo ed (\m n -> nn64.isum2 bs sl (\i k -> if (tokens[i][k] == m) then dws[i][k][n] else 0)))
   in  (dwt, dwp, dwa, dba, dwqry, dbqry, dwkey, dbkey, dwval, dbval, dwo, dbo,  dwm, dbm, dwu, dbu, dwd, dbd, dwf, dbf, dwc, dbc)

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

  let (wa, mwa, vwa) =
    adam_opt1 p.wa mp.wa vp.wa dp.wa step lt_r
  let (ba, mba, vba) =
    adam_opt1 p.ba mp.ba vp.ba dp.ba step lt_r

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

  let (wm, mwm, vwm) =
    adam_opt1 p.wm mp.wm vp.wm dp.wm step lt_r
  let (bm, mbm, vbm) =
    adam_opt1 p.bm mp.bm vp.bm dp.bm step lt_r

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

  let (wf, mwf, vwf) =
    adam_opt1 p.wf mp.wf vp.wf dp.wf step lt_r
  let (bf, mbf, vbf) =
    adam_opt1 p.bf mp.bf vp.bf dp.bf step lt_r

  let (bc, mbc, vbc) =
    adam_opt1 p.bc mp.bc vp.bc dp.bc step lt_r

  let p'  = to_params wt wp wa ba wqry bqry wkey bkey wval bval wo bo wm bm wu bu wd bd wf bf wc bc
  let mp' = to_params mwt mwp mwa mba mwqry mbqry mwkey mbkey mwval mbval mwo mbo mwm mbm mwu mbu mwd mbd mwf mbf mwc mbc
  let vp' = to_params vwt vwp vwa vba vwqry vbqry vwkey vbkey vwval vbval vwo vbo vwm vbm vwu vbu vwd vbd vwf vbf vwc vbc
  in (p', mp', vp')

def cal_step [bs] (p : params) (mp : params) (vp : params)
  (batch : [bs][sl]i64) (mask : [sl][sl]f64)
  (step : i64) steps :
  (params,  params,  params) =
  -- cal gradient
  let (dwt, dwp, dwa, dba, dwqry, dbqry, dwkey, dbkey, dwval, dbval, dwo, dbo, dwm, dbm, dwu, dbu, dwd, dbd, dwf, dbf, dwc, dbc) =
    grad p batch mask
  let dp = to_params dwt dwp dwa dba dwqry dbqry dwkey dbkey dwval dbval dwo dbo dwm dbm dwu dbu dwd dbd dwf dbf dwc dbc
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
  let wa = imap1 ed (\_ -> 0)
  let ba = imap1 ed (\_ -> 0)
  let wqry = imap2 ed ed (\_ _ -> 0)
  let bqry = imap1 ed (\_ -> 0)
  let wkey = imap2 ed ed (\_ _ -> 0)
  let bkey = imap1 ed (\_ -> 0)
  let wval = imap2 ed ed (\_ _ -> 0)
  let bval = imap1 ed (\_ -> 0)
  let wo = imap2 ed ed (\_ _ -> 0)
  let bo = imap1 ed (\_ -> 0)
  let wm = imap1 ed (\_ -> 0)
  let bm = imap1 ed (\_ -> 0)
  let wu = imap2 fd ed (\_ _ -> 0)
  let bu = imap1 fd (\_ -> 0)
  let wd = imap2 ed fd (\_ _ -> 0)
  let bd = imap1 ed (\_ -> 0)
  let wf = imap1 ed (\_ -> 0)
  let bf = imap1 ed (\_ -> 0)
  let wc = imap2 vo ed (\_ _ -> 0)
  let bc = imap1 vo (\_ -> 0)
  in {wt, wp, wa, ba, wqry, bqry, wkey, bkey, wval, bval, wo, bo, wm, bm, wu, bu, wd, bd, wf, bf, wc, bc}