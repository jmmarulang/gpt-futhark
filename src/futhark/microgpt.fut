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

def forward_seq [bs] :
      (mask: [16][16]real)
  -> (wp: [16][16]real)
  -> (wqry: [16][16]real)
  -> (wkey: [16][16]real)
  -> (wval: [16][16]real)
  -> (wo: [16][16]real)
  -> (wu: [64][16]real)
  -> (wd: [16][64]real)
  -> (wc: [27][16]real)
  -> (ws: [bs][16][16]real)
  -> [bs][16][27]real =
  #[unsafe]
  \(mask: [16][16]real) (wp: [16][16]real)
  (wqry: [16][16]real) (wkey: [16][16]real) (wval: [16][16]real)
  (wo: [16][16]real) (wu: [64][16]real) (wd: [16][64]real)
  (wc: [27][16]real) (ws: [bs][16][16]real) ->

(let x0 = (imap1 bs (\i23 -> (imap2 16 16 (\i24 i25 -> (wp[i24][i25] F.+ ws[i23][i24][i25])))))
in (let x1 = (imap1 bs (\i26 -> (imap1 16 (\i27 -> (let x28 = (imap1 16 (\i32 -> (x0[i26][i27][i32] F.* x0[i26][i27][i32])))
in (let x29 = ((isum1 16 (\i33 -> x28[i33])) F./ fromi64 16)
in (let x30 = (F.sqrt (x29 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i31 -> (x0[i26][i27][i31] F.* (one F./ x30)))))))))))
in (let x2 = (imap1 bs (\i34 -> (imap1 16 (\i35 -> (let x36 = (imap1 16 (\i40 -> (x1[i34][i35][i40] F.* x1[i34][i35][i40])))
in (let x37 = ((isum1 16 (\i41 -> x36[i41])) F./ fromi64 16)
in (let x38 = (F.sqrt (x37 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i39 -> (x1[i34][i35][i39] F.* (one F./ x38)))))))))))
in (let x3 = (imap1 bs (\i42 -> (imap1 16 (\i43 -> (imap1 16 (\i44 -> (isum1 16 (\i45 -> (wqry[i44][i45] F.* x2[i42][i43][i45])))))))))
in (let x4 = (imap1 bs (\i46 -> (imap1 16 (\i47 -> (imap1 16 (\i48 -> (isum1 16 (\i49 -> (wkey[i48][i49] F.* x2[i46][i47][i49])))))))))
in (let x5 = (imap1 bs (\i50 -> (imap1 16 (\i51 -> (imap1 16 (\i52 -> (isum1 16 (\i53 -> (wval[i52][i53] F.* x2[i50][i51][i53])))))))))
in (let x6 = (imap1 bs (\i54 -> (imap1 16 (\i55 -> (imap1 4 (\i56 -> (imap1 4 (\i57 -> x3[i54][i55][((i56 * 4) + i57)]))))))))
in (let x7 = (imap1 bs (\i58 -> (imap1 16 (\i59 -> (imap1 4 (\i60 -> (imap1 4 (\i61 -> x4[i58][i59][((i60 * 4) + i61)]))))))))
in (let x8 = (imap1 bs (\i62 -> (imap1 16 (\i63 -> (imap1 4 (\i64 -> (imap1 4 (\i65 -> x5[i62][i63][((i64 * 4) + i65)]))))))))
in (let x9 = (imap1 bs (\i66 -> (imap1 4 (\i67 -> (imap1 16 (\i68 -> (imap1 4 (\i69 -> x6[i66][i68][i67][i69]))))))))
in (let x10 = (imap1 bs (\i70 -> (imap1 4 (\i71 -> (imap1 16 (\i72 -> (imap1 4 (\i73 -> x7[i70][i72][i71][i73]))))))))
in (let x11 = (imap1 bs (\i74 -> (imap1 4 (\i75 -> (imap1 16 (\i76 -> (imap1 4 (\i77 -> x8[i74][i76][i75][i77]))))))))
in (let x12 = (imap1 bs (\i78 -> (imap1 4 (\i79 -> (let x80 = (imap1 16 (\i82 -> (let x84 = (isoftmax1 16 (\i83 -> (((isum1 4 (\i86 -> (x9[i78][i79][i82][i86] F.* x10[i78][i79][i83][i86]))) F./ fromi64 2) F.+ mask[i82][i83])))
in (imap1 16 (\i85 -> x84[i85])))))
in (imap1 16 (\i81 -> (imap1 4 (\i88 -> (isum1 16 (\i89 -> (x80[i81][i89] F.* x11[i78][i79][i89][i88]))))))))))))
in (let x13 = (imap1 bs (\i90 -> (imap1 16 (\i91 -> (imap1 4 (\i92 -> (imap1 4 (\i93 -> x12[i90][i92][i91][i93]))))))))
in (let x14 = (imap1 bs (\i94 -> (imap1 16 (\i95 -> (imap1 16 (\i96 -> x13[i94][i95][(i96 / 4)][(i96 % 4)]))))))
in (let x15 = (imap1 bs (\i97 -> (imap1 16 (\i98 -> (imap1 16 (\i99 -> (isum1 16 (\i100 -> (wo[i99][i100] F.* x14[i97][i98][i100])))))))))
in (let x16 = (imap3 bs 16 16 (\i101 i102 i103 -> (x1[i101][i102][i103] F.+ x15[i101][i102][i103])))
in (let x17 = (imap1 bs (\i104 -> (imap1 16 (\i105 -> (let x106 = (imap1 16 (\i110 -> (x16[i104][i105][i110] F.* x16[i104][i105][i110])))
in (let x107 = ((isum1 16 (\i111 -> x106[i111])) F./ fromi64 16)
in (let x108 = (F.sqrt (x107 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i109 -> (x16[i104][i105][i109] F.* (one F./ x108)))))))))))
in (let x18 = (imap1 bs (\i112 -> (imap1 16 (\i113 -> (imap1 64 (\i114 -> (isum1 16 (\i115 -> (wu[i114][i115] F.* x17[i112][i113][i115])))))))))
in (let x19 = (imap3 bs 16 64 (\i116 i117 i118 -> (F.max x18[i116][i117][i118] zero)))
in (let x20 = (imap1 bs (\i119 -> (imap1 16 (\i120 -> (imap1 16 (\i121 -> (isum1 64 (\i122 -> (wd[i121][i122] F.* x19[i119][i120][i122])))))))))
in (let x21 = (imap3 bs 16 16 (\i123 i124 i125 -> (x16[i123][i124][i125] F.+ x20[i123][i124][i125])))
in (imap1 bs (\i22 -> (imap1 16 (\i126 -> (imap1 27 (\i127 -> (isum1 16 (\i128 -> (wc[i127][i128] F.* x21[i22][i126][i128])))))))))))))))))))))))))))))))

def cal_loss [bs] : (mask: [16][16]real)
  -> (wp: [16][16]real)
  -> (wqry: [16][16]real)
  -> (wkey: [16][16]real)
  -> (wval: [16][16]real)
  -> (wo: [16][16]real)
  -> (wu: [64][16]real)
  -> (wd: [16][64]real)
  -> (wc: [27][16]real)
  -> (ws: [bs][16][16]real)
  -> (target: [bs][16][27]real)
  -> real =
  #[unsafe]
  \(mask: [16][16]real) (wp: [16][16]real)
  (wqry: [16][16]real) (wkey: [16][16]real) (wval: [16][16]real)
  (wo: [16][16]real) (wu: [64][16]real) (wd: [16][64]real)
  (wc: [27][16]real) (ws: [bs][16][16]real) (target: [bs][16][27]real) ->

(let x0 = (imap1 bs (\i25 -> (imap2 16 16 (\i26 i27 -> (wp[i26][i27] F.+ ws[i25][i26][i27])))))
in (let x1 = (imap1 bs (\i28 -> (imap1 16 (\i29 -> (let x30 = (imap1 16 (\i34 -> (x0[i28][i29][i34] F.* x0[i28][i29][i34])))
in (let x31 = ((isum1 16 (\i35 -> x30[i35])) F./ fromi64 16)
in (let x32 = (F.sqrt (x31 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i33 -> (x0[i28][i29][i33] F.* (one F./ x32)))))))))))
in (let x2 = (imap1 bs (\i36 -> (imap1 16 (\i37 -> (let x38 = (imap1 16 (\i42 -> (x1[i36][i37][i42] F.* x1[i36][i37][i42])))
in (let x39 = ((isum1 16 (\i43 -> x38[i43])) F./ fromi64 16)
in (let x40 = (F.sqrt (x39 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i41 -> (x1[i36][i37][i41] F.* (one F./ x40)))))))))))
in (let x3 = (imap1 bs (\i44 -> (imap1 16 (\i45 -> (imap1 16 (\i46 -> (isum1 16 (\i47 -> (wqry[i46][i47] F.* x2[i44][i45][i47])))))))))
in (let x4 = (imap1 bs (\i48 -> (imap1 16 (\i49 -> (imap1 16 (\i50 -> (isum1 16 (\i51 -> (wkey[i50][i51] F.* x2[i48][i49][i51])))))))))
in (let x5 = (imap1 bs (\i52 -> (imap1 16 (\i53 -> (imap1 16 (\i54 -> (isum1 16 (\i55 -> (wval[i54][i55] F.* x2[i52][i53][i55])))))))))
in (let x6 = (imap1 bs (\i56 -> (imap1 16 (\i57 -> (imap1 4 (\i58 -> (imap1 4 (\i59 -> x3[i56][i57][((i58 * 4) + i59)]))))))))
in (let x7 = (imap1 bs (\i60 -> (imap1 16 (\i61 -> (imap1 4 (\i62 -> (imap1 4 (\i63 -> x4[i60][i61][((i62 * 4) + i63)]))))))))
in (let x8 = (imap1 bs (\i64 -> (imap1 16 (\i65 -> (imap1 4 (\i66 -> (imap1 4 (\i67 -> x5[i64][i65][((i66 * 4) + i67)]))))))))
in (let x9 = (imap1 bs (\i68 -> (imap1 4 (\i69 -> (imap1 16 (\i70 -> (imap1 4 (\i71 -> x6[i68][i70][i69][i71]))))))))
in (let x10 = (imap1 bs (\i72 -> (imap1 4 (\i73 -> (imap1 16 (\i74 -> (imap1 4 (\i75 -> x7[i72][i74][i73][i75]))))))))
in (let x11 = (imap1 bs (\i76 -> (imap1 4 (\i77 -> (imap1 16 (\i78 -> (imap1 4 (\i79 -> x8[i76][i78][i77][i79]))))))))
in (let x12 = (imap1 bs (\i80 -> (imap1 4 (\i81 -> (let x82 = (imap1 16 (\i84 -> (let x86 = (isoftmax1 16 (\i85 -> (((isum1 4 (\i88 -> (x9[i80][i81][i84][i88] F.* x10[i80][i81][i85][i88]))) F./ fromi64 2) F.+ mask[i84][i85])))
in (imap1 16 (\i87 -> x86[i87])))))
in (imap1 16 (\i83 -> (imap1 4 (\i90 -> (isum1 16 (\i91 -> (x82[i83][i91] F.* x11[i80][i81][i91][i90]))))))))))))
in (let x13 = (imap1 bs (\i92 -> (imap1 16 (\i93 -> (imap1 4 (\i94 -> (imap1 4 (\i95 -> x12[i92][i94][i93][i95]))))))))
in (let x14 = (imap1 bs (\i96 -> (imap1 16 (\i97 -> (imap1 16 (\i98 -> x13[i96][i97][(i98 / 4)][(i98 % 4)]))))))
in (let x15 = (imap1 bs (\i99 -> (imap1 16 (\i100 -> (imap1 16 (\i101 -> (isum1 16 (\i102 -> (wo[i101][i102] F.* x14[i99][i100][i102])))))))))
in (let x16 = (imap3 bs 16 16 (\i103 i104 i105 -> (x1[i103][i104][i105] F.+ x15[i103][i104][i105])))
in (let x17 = (imap1 bs (\i106 -> (imap1 16 (\i107 -> (let x108 = (imap1 16 (\i112 -> (x16[i106][i107][i112] F.* x16[i106][i107][i112])))
in (let x109 = ((isum1 16 (\i113 -> x108[i113])) F./ fromi64 16)
in (let x110 = (F.sqrt (x109 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i111 -> (x16[i106][i107][i111] F.* (one F./ x110)))))))))))
in (let x18 = (imap1 bs (\i114 -> (imap1 16 (\i115 -> (imap1 64 (\i116 -> (isum1 16 (\i117 -> (wu[i116][i117] F.* x17[i114][i115][i117])))))))))
in (let x19 = (imap3 bs 16 64 (\i118 i119 i120 -> (F.max x18[i118][i119][i120] zero)))
in (let x20 = (let x121 = (imap1 bs (\i124 -> (imap1 16 (\i125 -> (imap1 16 (\i126 -> (isum1 64 (\i127 -> (wd[i126][i127] F.* x19[i124][i125][i127])))))))))
in (let x122 = (imap3 bs 16 16 (\i128 i129 i130 -> (x16[i128][i129][i130] F.+ x121[i128][i129][i130])))
in (imap1 bs (\i123 -> (imap1 16 (\i131 -> (imap1 27 (\i132 -> (isum1 16 (\i133 -> (wc[i132][i133] F.* x122[i123][i131][i133])))))))))))
in (let x21 = (imap3 bs 16 27 (\i134 i135 i136 -> (target[i134][i135][i136] F.* (F.neg (F.log (let x138 = (isoftmax1 27 (\i137 -> x20[i134][i135][i137]))
in x138[i136]))))))
in ((isum3 bs 16 27 (\i22 i23 i24 -> x21[i22][i23][i24])) F./ fromi64 (bs * 16))))))))))))))))))))))))


def grad [bs] : (mask: [16][16]real)
  -> (wp: [16][16]real)
  -> (wqry: [16][16]real)
  -> (wkey: [16][16]real)
  -> (wval: [16][16]real)
  -> (wo: [16][16]real)
  -> (wu: [64][16]real)
  -> (wd: [16][64]real)
  -> (wc: [27][16]real)
  -> (ws: [bs][16][16]real)
  -> (target: [bs][16][27]real)
  ->
  (
    [bs][16][16]real, --ws
    [16][16]real, -- position embeddings
    [16][16]real, -- query weights
    [16][16]real, -- key weights
    [16][16]real, -- value weights
    [16][16]real, -- output weights
    [64][16]real, -- MLP up-projection
    [16][64]real, -- MLP down-projection
    [27][16]real  -- output projection
  ) =
  #[unsafe]
  \(mask: [16][16]real) (wp: [16][16]real)
  (wqry: [16][16]real) (wkey: [16][16]real) (wval: [16][16]real)
  (wo: [16][16]real) (wu: [64][16]real) (wd: [16][64]real)
  (wc: [27][16]real) (ws: [bs][16][16]real) (target: [bs][16][27]real) ->

let x0 = (imap1 bs (\i1 -> (let x2 = (imap1 16 (\i14 -> (let x15 = ((isum1 16 (\i18 -> ((wp[i14][i18] F.+ ws[i1][i14][i18]) F.* (wp[i14][i18] F.+ ws[i1][i14][i18])))) F./ fromi64 16)
in (let x16 = (F.sqrt (x15 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i17 -> ((wp[i14][i17] F.+ ws[i1][i14][i17]) F.* (one F./ x16))))))))
in (let x3 = (imap1 16 (\i19 -> (let x20 = ((isum1 16 (\i23 -> (x2[i19][i23] F.* x2[i19][i23]))) F./ fromi64 16)
in (let x21 = (F.sqrt (x20 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i22 -> (x2[i19][i22] F.* (one F./ x21))))))))
in (let x4 = (imap1 16 (\i24 -> (imap1 16 (\i25 -> (isum1 16 (\i26 -> (wqry[i25][i26] F.* x3[i24][i26])))))))
in (let x5 = (imap1 16 (\i27 -> (imap1 16 (\i28 -> (isum1 16 (\i29 -> (wkey[i28][i29] F.* x3[i27][i29])))))))
in (let x6 = (imap1 16 (\i30 -> (imap1 16 (\i31 -> (isum1 16 (\i32 -> (wval[i31][i32] F.* x3[i30][i32])))))))
in (let x7 = (imap1 4 (\i33 -> (let x34 = (imap1 16 (\i36 -> (let x38 = (isoftmax1 16 (\i37 -> (((isum1 4 (\i40 -> (x4[i36][((i33 * 4) + i40)] F.* x5[i37][((i33 * 4) + i40)]))) F./ fromi64 2) F.+ mask[i36][i37])))
in (imap1 16 (\i39 -> x38[i39])))))
in (imap1 16 (\i35 -> (imap1 4 (\i41 -> (isum1 16 (\i42 -> (x34[i35][i42] F.* x6[i42][((i33 * 4) + i41)]))))))))))
in (let x8 = (imap1 16 (\i43 -> (imap1 16 (\i44 -> x7[(i44 / 4)][i43][(i44 % 4)]))))
in (let x9 = (imap1 16 (\i45 -> (imap1 16 (\i46 -> (x2[i45][i46] F.+ (isum1 16 (\i47 -> (wo[i46][i47] F.* x8[i45][i47]))))))))
in (let x10 = (imap1 16 (\i48 -> (let x49 = ((isum1 16 (\i52 -> (x9[i48][i52] F.* x9[i48][i52]))) F./ fromi64 16)
in (let x50 = (F.sqrt (x49 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i51 -> (x9[i48][i51] F.* (one F./ x50))))))))
in (let x11 = (imap2 16 64 (\i53 i54 -> (F.max (isum1 16 (\i55 -> (wu[i54][i55] F.* x10[i53][i55]))) zero)))
in (let x12 = (imap1 16 (\i56 -> (imap1 16 (\i57 -> (x9[i56][i57] F.+ (isum1 64 (\i58 -> (wd[i57][i58] F.* x11[i56][i58]))))))))
in (imap1 16 (\i13 -> (imap1 27 (\i59 -> (isum1 16 (\i60 -> (wc[i59][i60] F.* x12[i13][i60]))))))))))))))))))))
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
let x99 = (imap1 bs (\i100 -> (imap1 16 (\i101 -> (imap1 16 (\i102 -> (isum1 16 (\i103 -> (wqry[i102][i103] F.* x92[i100][i101][i103])))))))))
let x104 = (imap1 bs (\i105 -> (imap1 16 (\i106 -> (imap1 16 (\i107 -> (isum1 16 (\i108 -> (wkey[i107][i108] F.* x92[i105][i106][i108])))))))))
let x109 = (imap1 bs (\i110 -> (imap1 16 (\i111 -> (imap1 16 (\i112 -> (isum1 16 (\i113 -> (wval[i112][i113] F.* x92[i110][i111][i113])))))))))
let x114 = (imap1 bs (\i115 -> (imap1 4 (\i116 -> (let x117 = (imap1 16 (\i119 -> (let x121 = (isoftmax1 16 (\i120 -> (((isum1 4 (\i123 -> (x99[i115][i119][((i116 * 4) + i123)] F.* x104[i115][i120][((i116 * 4) + i123)]))) F./ fromi64 2) F.+ mask[i119][i120])))
in (imap1 16 (\i122 -> x121[i122])))))
in (imap1 16 (\i118 -> (imap1 4 (\i124 -> (isum1 16 (\i125 -> (x117[i118][i125] F.* x109[i115][i125][((i116 * 4) + i124)]))))))))))))
let x126 = (imap1 bs (\i127 -> (imap1 16 (\i128 -> (imap1 16 (\i129 -> x114[i127][(i129 / 4)][i128][(i129 % 4)]))))))
let x130 = (imap1 bs (\i131 -> (imap1 16 (\i132 -> (imap1 16 (\i133 -> (x85[i131][i132][i133] F.+ (isum1 16 (\i134 -> (wo[i133][i134] F.* x126[i131][i132][i134]))))))))))
let x135 = (imap1 bs (\i136 -> (imap1 16 (\i137 -> (let x138 = ((isum1 16 (\i141 -> (x130[i136][i137][i141] F.* x130[i136][i137][i141]))) F./ fromi64 16)
in (let x139 = (F.sqrt (x138 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i140 -> (x130[i136][i137][i140] F.* (one F./ x139))))))))))
let x142 = (imap1 bs (\i143 -> (imap2 16 64 (\i144 i145 -> (F.max (isum1 16 (\i146 -> (wu[i145][i146] F.* x135[i143][i144][i146]))) zero)))))
let x147 = (imap1 bs (\i148 -> (imap1 16 (\i149 -> (imap1 16 (\i150 -> (x130[i148][i149][i150] F.+ (isum1 64 (\i151 -> (wd[i150][i151] F.* x142[i148][i149][i151]))))))))))
let x152 = (imap1 bs (\i153 -> (imap1 16 (\i154 -> (imap1 16 (\i155 -> (isum1 27 (\i156 -> (wc[i156][i155] F.* x81[i153][i154][i156])))))))))
let x157 = (imap1 bs (\i158 -> (imap1 16 (\i159 -> (imap1 64 (\i160 -> (isum1 16 (\i161 -> (wd[i161][i160] F.* x152[i158][i159][i161])))))))))
let x162 = (imap1 bs (\i163 -> (imap1 16 (\i164 -> (imap1 16 (\i165 -> (isum1 64 (\i166 -> (wu[i166][i165] F.* ((indicatorp (isum1 16 (\i167 -> (wu[i166][i167] F.* x135[i163][i164][i167])))) F.* x157[i163][i164][i166]))))))))))
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
let dwkey = (imap1 16 (\i301 -> (imap1 16 (\i302 -> (isum1 bs (\i303 -> (isum1 16 (\i304 -> (x233[i303][i304][i301] F.* x92[i303][i304][i302])))))))))
let dwqry = (imap1 16 (\i305 -> (imap1 16 (\i306 -> (isum1 bs (\i307 -> (isum1 16 (\i308 -> (x238[i307][i308][i305] F.* x92[i307][i308][i306])))))))))
let dwval = (imap1 16 (\i309 -> (imap1 16 (\i310 -> (isum1 bs (\i311 -> (isum1 16 (\i312 -> (x228[i311][i312][i309] F.* x92[i311][i312][i310])))))))))
let dwo = (imap1 16 (\i313 -> (imap1 16 (\i314 -> (isum1 bs (\i315 -> (isum1 16 (\i316 -> (x190[i315][i316][i313] F.* x126[i315][i316][i314])))))))))
let dmask = (imap1 16 (\i317 -> (imap1 16 (\i320 -> (isum1 bs (\i318 -> (isum1 4 (\i319 -> (x204[i318][i319][i317][i320] F.* (x218[i318][i319][i317][i320] F.+ (F.neg x223[i318][i319][i317])))))))))))
let dwu = (imap1 64 (\i321 -> (imap1 16 (\i322 -> (isum1 bs (\i323 -> (isum1 16 (\i324 -> (((indicatorp (isum1 16 (\i325 -> (wu[i321][i325] F.* x135[i323][i324][i325])))) F.* x157[i323][i324][i321]) F.* x135[i323][i324][i322])))))))))
let dwd = (imap1 16 (\i326 -> (imap1 64 (\i327 -> (isum1 bs (\i328 -> (isum1 16 (\i329 -> (x152[i328][i329][i326] F.* x142[i328][i329][i327])))))))))
let dwc = (imap1 27 (\i330 -> (imap1 16 (\i331 -> (isum1 bs (\i332 -> (isum1 16 (\i333 -> (x81[i332][i333][i330] F.* x147[i332][i333][i331])))))))))
let dws = (imap1 bs (\i334 -> (imap1 16 (\i335 -> (imap1 16 (\i336 -> (((x272[i334][i335][i336] F.* (one F./ x284[i334][i335])) F.+ ((wp[i335][i336] F.+ ws[i334][i335][i336]) F.* x294[i334][i335][i336])) F.+ (x294[i334][i335][i336] F.* (wp[i335][i336] F.+ ws[i334][i335][i336])))))))))
let dtarget = (imap3 bs 16 27 (\i337 i338 i339 -> (x61[i337][i338][i339] F.* (F.neg (F.log (let x341 = (isoftmax1 27 (\i340 -> x0[i337][i338][i340]))
in x341[i339]))))))

in (dws, dwp, dwqry, dwkey, dwval, dwo, dwu, dwd, dwc)
}

module nn64 = nn f64

let sl : i64 = 16
let ed : i64 = 16
let ah : i64 = 4
let hd : i64 = 4
let fd : i64 = 64
let vo : i64 = 27

type params = {
  wt:   [vo][ed]f64, -- token embeddings
  wp:   [sl][ed]f64, -- position embeddings
  wqry:  [ed][ed]f64, -- query weights
  wkey:  [ed][ed]f64, -- key weights
  wval:  [ed][ed]f64, -- value weights
  wo:  [ed][ed]f64, -- output weights
  wu:   [fd][ed]f64, -- MLP up-projection
  wd: [ed][fd]f64, -- MLP down-projection
  wc:  [vo][ed]f64  -- output projection
}

entry to_params (wt: [vo][ed]f64)  (wp: [sl][ed]f64)
    (wqry: [ed][ed]f64) (wkey: [ed][ed]f64) (wval: [ed][ed]f64)
    (wo: [ed][ed]f64) (wu: [fd][ed]f64) (wd: [ed][fd]f64)
    (wc: [vo][ed]f64) : params =
    {wt, wp, wqry, wkey, wval, wo, wu, wd, wc}

def from_params (p : params) :
  (
  [vo][ed]f64, -- token embeddings
  [sl][ed]f64, -- position embeddings
  [ed][ed]f64, -- query weights
  [ed][ed]f64, -- key weights
  [ed][ed]f64, -- value weights
  [ed][ed]f64, -- output weights
  [fd][ed]f64, -- MLP up-projection
  [ed][fd]f64, -- MLP down-projection
  [vo][ed]f64  -- output projection
  ) =
  let {wt, wp, wqry, wkey, wval, wo, wu, wd, wc} = p
  in (wt, wp, wqry, wkey, wval, wo, wu, wd, wc)

entry forward [bs] (p : params) (tokens : [bs][sl]i64) (mask : [sl][sl]f64) : [bs][sl][vo]f64 =
   let {wt, wp, wqry, wkey, wval, wo, wu, wd, wc} = p
   let ws = (imap3 bs sl ed (\i j k -> wt[tokens[i][j]][k]))
   in (nn64.forward_seq
        (mask :> [16][16]f64)
        (wp   :> [16][16]f64)
        (wqry :> [16][16]f64)
        (wkey :> [16][16]f64)
        (wval :> [16][16]f64)
        (wo   :> [16][16]f64)
        (wu   :> [64][16]f64)
        (wd   :> [16][64]f64)
        (wc   :> [27][16]f64)
        (ws   :> [bs][16][16]f64)
              :> [bs][sl][vo]f64)

entry cal_target [bs] (tokens : [bs][sl]i64) : [bs][sl]i64 =
  imap2 bs sl (\i j -> if (j < sl - 1) then tokens[i][j + 1] else vo)

entry cal_target_mask [bs] (n : i64) (target : [bs][sl]i64) : [bs][sl][vo]f64 =
  imap3 bs sl vo (\i j k -> (if ((j < (n - 1)) && (target[i][j] == k)) then 1 else 0))

entry loss [bs] (dl : i64) (p : params) (tokens : [bs][sl]i64) (mask : [sl][sl]f64) : f64 =
   let {wt, wp, wqry, wkey, wval, wo, wu, wd, wc} = p
   let target = cal_target_mask dl (cal_target tokens)
   let ws = (imap3 bs sl ed (\i j k -> wt[tokens[i][j]][k]))
   in (nn64.cal_loss
        (mask   :> [16][16]f64)
        (wp     :> [16][16]f64)
        (wqry   :> [16][16]f64)
        (wkey   :> [16][16]f64)
        (wval   :> [16][16]f64)
        (wo     :> [16][16]f64)
        (wu     :> [64][16]f64)
        (wd     :> [16][64]f64)
        (wc     :> [27][16]f64)
        (ws     :> [bs][16][16]f64)
        (target :> [bs][16][27]f64)
                :> f64)

def grad [bs] (dl : i64) (p : params) (tokens : [bs][sl]i64) (mask : [sl][sl]f64) :
        (
        [vo][ed]f64, --token embedding
        [sl][ed]f64, -- position embeddings
        [ed][ed]f64, -- query weights
        [ed][ed]f64, -- key weights
        [ed][ed]f64, -- value weights
        [ed][ed]f64, -- output weights
        [fd][ed]f64, -- MLP up-projection
        [ed][fd]f64, -- MLP down-projection
        [vo][ed]f64  -- output projection
        ) =
   let {wt, wp, wqry, wkey, wval, wo, wu, wd, wc} = p
   -- cal targets
   let target = cal_target_mask dl (cal_target tokens)
   -- cal voc embedding
   let ws = (imap3 bs sl ed (\i j k -> wt[tokens[i][j]][k]))
   -- cal gradient
   let (dws, dwp, dwqry, dwkey, dwval, dwo, dwu, dwd, dwc) =
    (nn64.grad
        (mask   :> [16][16]f64)
        (wp     :> [16][16]f64)
        (wqry   :> [16][16]f64)
        (wkey   :> [16][16]f64)
        (wval   :> [16][16]f64)
        (wo     :> [16][16]f64)
        (wu     :> [64][16]f64)
        (wd     :> [16][64]f64)
        (wc     :> [27][16]f64)
        (ws     :> [bs][16][16]f64)
        (target :> [bs][16][27]f64)
                :>
        (
        [bs][sl][ed]f64, --ws
        [sl][ed]f64, -- position embeddings
        [ed][ed]f64, -- query weights
        [ed][ed]f64, -- key weights
        [ed][ed]f64, -- value weights
        [ed][ed]f64, -- output weights
        [fd][ed]f64, -- MLP up-projection
        [ed][fd]f64, -- MLP down-projection
        [vo][ed]f64  -- output projection
        ))
   let dwt = (imap2 vo ed (\m n -> nn64.isum2 bs sl (\i k -> if (tokens[i][k] == m) then dws[i][k][n] else 0)))
   in  (dwt, dwp, dwqry, dwkey, dwval, dwo, dwu, dwd, dwc)

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
  let (wkey, mwkey, vwkey) =
    adam_opt2 p.wkey mp.wkey vp.wkey dp.wkey step lt_r
  let (wval, mwval, vwval) =
    adam_opt2 p.wval mp.wval vp.wval dp.wval step lt_r
  let (wo, mwo, vwo) =
    adam_opt2 p.wo mp.wo vp.wo dp.wo step lt_r
  let (wu, mwu, vwu) =
    adam_opt2 p.wu mp.wu vp.wu dp.wu step lt_r
  let (wd, mwd, vwd) =
    adam_opt2 p.wd mp.wd vp.wd dp.wd step lt_r
  let (wc, mwc, vwc) =
    adam_opt2 p.wc mp.wc vp.wc dp.wc step lt_r
  let p' = to_params wt wp wqry wkey wval wo wu wd wc
  let mp' = to_params mwt mwp mwqry mwkey mwval mwo mwu mwd mwc
  let vp' = to_params vwt vwp vwqry vwkey vwval vwo vwu vwd vwc
  in (p', mp', vp')

def cal_step [bs] (dl : i64) (p : params) (mp : params) (vp : params)
  (batch : [bs][sl]i64) (mask : [sl][sl]f64)
  (step : i64) steps :
  (params,  params,  params) =
  -- cal gradient
  let (dwt, dwp, dwqry, dwkey, dwval, dwo, dwu, dwd, dwc) =
    grad dl p batch mask
  let dp = to_params dwt dwp dwqry dwkey dwval dwo dwu dwd dwc
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
      let (p', mp', vp') = (cal_step sl p' mp' vp' batch mask step steps)
      in (p', mp', vp')
  in ((from_params new_p), (from_params new_mp), (from_params new_vp))

entry zero_params : params =
  let wt = imap2 vo ed (\_ _ -> 0)
  let wp = imap2 sl ed (\_ _ -> 0)
  let wqry = imap2 ed ed (\_ _ -> 0)
  let wkey = imap2 ed ed (\_ _ -> 0)
  let wval = imap2 ed ed (\_ _ -> 0)
  let wo = imap2 ed ed (\_ _ -> 0)
  let wu = imap2 fd ed (\_ _ -> 0)
  let wd = imap2 ed fd (\_ _ -> 0)
  let wc = imap2 vo ed (\_ _ -> 0)
  in {wt, wp, wqry, wkey, wval, wo, wu, wd, wc}