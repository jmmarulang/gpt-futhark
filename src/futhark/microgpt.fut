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

def forward_seq :
      (mask: [16][16]real)
  -> (wp: [16][16]real)
  -> (wqry: [16][16]real)
  -> (wkey: [16][16]real)
  -> (wval: [16][16]real)
  -> (wo: [16][16]real)
  -> (wu: [64][16]real)
  -> (wd: [16][64]real)
  -> (wc: [27][16]real)
  -> (ws: [5][16][16]real)
  -> [5][16][27]real =
  #[unsafe]
  \(mask: [16][16]real) (wp: [16][16]real)
  (wqry: [16][16]real) (wkey: [16][16]real) (wval: [16][16]real)
  (wo: [16][16]real) (wu: [64][16]real) (wd: [16][64]real)
  (wc: [27][16]real) (ws: [5][16][16]real) ->

(let x0 = (imap1 5 (\i23 -> (imap2 16 16 (\i24 i25 -> (wp[i24][i25] F.+ ws[i23][i24][i25])))))
in (let x1 = (imap1 5 (\i26 -> (imap1 16 (\i27 -> (let x28 = (imap1 16 (\i32 -> (x0[i26][i27][i32] F.* x0[i26][i27][i32])))
in (let x29 = ((isum1 16 (\i33 -> x28[i33])) F./ fromi64 16)
in (let x30 = (F.sqrt (x29 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i31 -> (x0[i26][i27][i31] F.* (one F./ x30)))))))))))
in (let x2 = (imap1 5 (\i34 -> (imap1 16 (\i35 -> (let x36 = (imap1 16 (\i40 -> (x1[i34][i35][i40] F.* x1[i34][i35][i40])))
in (let x37 = ((isum1 16 (\i41 -> x36[i41])) F./ fromi64 16)
in (let x38 = (F.sqrt (x37 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i39 -> (x1[i34][i35][i39] F.* (one F./ x38)))))))))))
in (let x3 = (imap1 5 (\i42 -> (imap1 16 (\i43 -> (imap1 16 (\i44 -> (isum1 16 (\i45 -> (wqry[i44][i45] F.* x2[i42][i43][i45])))))))))
in (let x4 = (imap1 5 (\i46 -> (imap1 16 (\i47 -> (imap1 16 (\i48 -> (isum1 16 (\i49 -> (wkey[i48][i49] F.* x2[i46][i47][i49])))))))))
in (let x5 = (imap1 5 (\i50 -> (imap1 16 (\i51 -> (imap1 16 (\i52 -> (isum1 16 (\i53 -> (wval[i52][i53] F.* x2[i50][i51][i53])))))))))
in (let x6 = (imap1 5 (\i54 -> (imap1 16 (\i55 -> (imap1 4 (\i56 -> (imap1 4 (\i57 -> x3[i54][i55][((i56 * 4) + i57)]))))))))
in (let x7 = (imap1 5 (\i58 -> (imap1 16 (\i59 -> (imap1 4 (\i60 -> (imap1 4 (\i61 -> x4[i58][i59][((i60 * 4) + i61)]))))))))
in (let x8 = (imap1 5 (\i62 -> (imap1 16 (\i63 -> (imap1 4 (\i64 -> (imap1 4 (\i65 -> x5[i62][i63][((i64 * 4) + i65)]))))))))
in (let x9 = (imap1 5 (\i66 -> (imap1 4 (\i67 -> (imap1 16 (\i68 -> (imap1 4 (\i69 -> x6[i66][i68][i67][i69]))))))))
in (let x10 = (imap1 5 (\i70 -> (imap1 4 (\i71 -> (imap1 16 (\i72 -> (imap1 4 (\i73 -> x7[i70][i72][i71][i73]))))))))
in (let x11 = (imap1 5 (\i74 -> (imap1 4 (\i75 -> (imap1 16 (\i76 -> (imap1 4 (\i77 -> x8[i74][i76][i75][i77]))))))))
in (let x12 = (imap1 5 (\i78 -> (imap1 4 (\i79 -> (let x80 = (imap1 16 (\i82 -> (let x84 = (isoftmax1 16 (\i83 -> (((isum1 4 (\i86 -> (x9[i78][i79][i82][i86] F.* x10[i78][i79][i83][i86]))) F./ fromi64 2) F.+ mask[i82][i83])))
in (imap1 16 (\i85 -> x84[i85])))))
in (imap1 16 (\i81 -> (imap1 4 (\i88 -> (isum1 16 (\i89 -> (x80[i81][i89] F.* x11[i78][i79][i89][i88]))))))))))))
in (let x13 = (imap1 5 (\i90 -> (imap1 16 (\i91 -> (imap1 4 (\i92 -> (imap1 4 (\i93 -> x12[i90][i92][i91][i93]))))))))
in (let x14 = (imap1 5 (\i94 -> (imap1 16 (\i95 -> (imap1 16 (\i96 -> x13[i94][i95][(i96 / 4)][(i96 % 4)]))))))
in (let x15 = (imap1 5 (\i97 -> (imap1 16 (\i98 -> (imap1 16 (\i99 -> (isum1 16 (\i100 -> (wo[i99][i100] F.* x14[i97][i98][i100])))))))))
in (let x16 = (imap3 5 16 16 (\i101 i102 i103 -> (x1[i101][i102][i103] F.+ x15[i101][i102][i103])))
in (let x17 = (imap1 5 (\i104 -> (imap1 16 (\i105 -> (let x106 = (imap1 16 (\i110 -> (x16[i104][i105][i110] F.* x16[i104][i105][i110])))
in (let x107 = ((isum1 16 (\i111 -> x106[i111])) F./ fromi64 16)
in (let x108 = (F.sqrt (x107 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i109 -> (x16[i104][i105][i109] F.* (one F./ x108)))))))))))
in (let x18 = (imap1 5 (\i112 -> (imap1 16 (\i113 -> (imap1 64 (\i114 -> (isum1 16 (\i115 -> (wu[i114][i115] F.* x17[i112][i113][i115])))))))))
in (let x19 = (imap3 5 16 64 (\i116 i117 i118 -> (F.max x18[i116][i117][i118] zero)))
in (let x20 = (imap1 5 (\i119 -> (imap1 16 (\i120 -> (imap1 16 (\i121 -> (isum1 64 (\i122 -> (wd[i121][i122] F.* x19[i119][i120][i122])))))))))
in (let x21 = (imap3 5 16 16 (\i123 i124 i125 -> (x16[i123][i124][i125] F.+ x20[i123][i124][i125])))
in (imap1 5 (\i22 -> (imap1 16 (\i126 -> (imap1 27 (\i127 -> (isum1 16 (\i128 -> (wc[i127][i128] F.* x21[i22][i126][i128])))))))))))))))))))))))))))))))

def cal_loss : (mask: [16][16]real)
  -> (wp: [16][16]real)
  -> (wqry: [16][16]real)
  -> (wkey: [16][16]real)
  -> (wval: [16][16]real)
  -> (wo: [16][16]real)
  -> (wu: [64][16]real)
  -> (wd: [16][64]real)
  -> (wc: [27][16]real)
  -> (ws: [5][16][16]real)
  -> (target: [5][16][27]real)
  -> real =
  #[unsafe]
  \(mask: [16][16]real) (wp: [16][16]real)
  (wqry: [16][16]real) (wkey: [16][16]real) (wval: [16][16]real)
  (wo: [16][16]real) (wu: [64][16]real) (wd: [16][64]real)
  (wc: [27][16]real) (ws: [5][16][16]real) (target: [5][16][27]real) ->

(let x0 = (imap1 5 (\i25 -> (imap2 16 16 (\i26 i27 -> (wp[i26][i27] F.+ ws[i25][i26][i27])))))
in (let x1 = (imap1 5 (\i28 -> (imap1 16 (\i29 -> (let x30 = (imap1 16 (\i34 -> (x0[i28][i29][i34] F.* x0[i28][i29][i34])))
in (let x31 = ((isum1 16 (\i35 -> x30[i35])) F./ fromi64 16)
in (let x32 = (F.sqrt (x31 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i33 -> (x0[i28][i29][i33] F.* (one F./ x32)))))))))))
in (let x2 = (imap1 5 (\i36 -> (imap1 16 (\i37 -> (let x38 = (imap1 16 (\i42 -> (x1[i36][i37][i42] F.* x1[i36][i37][i42])))
in (let x39 = ((isum1 16 (\i43 -> x38[i43])) F./ fromi64 16)
in (let x40 = (F.sqrt (x39 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i41 -> (x1[i36][i37][i41] F.* (one F./ x40)))))))))))
in (let x3 = (imap1 5 (\i44 -> (imap1 16 (\i45 -> (imap1 16 (\i46 -> (isum1 16 (\i47 -> (wqry[i46][i47] F.* x2[i44][i45][i47])))))))))
in (let x4 = (imap1 5 (\i48 -> (imap1 16 (\i49 -> (imap1 16 (\i50 -> (isum1 16 (\i51 -> (wkey[i50][i51] F.* x2[i48][i49][i51])))))))))
in (let x5 = (imap1 5 (\i52 -> (imap1 16 (\i53 -> (imap1 16 (\i54 -> (isum1 16 (\i55 -> (wval[i54][i55] F.* x2[i52][i53][i55])))))))))
in (let x6 = (imap1 5 (\i56 -> (imap1 16 (\i57 -> (imap1 4 (\i58 -> (imap1 4 (\i59 -> x3[i56][i57][((i58 * 4) + i59)]))))))))
in (let x7 = (imap1 5 (\i60 -> (imap1 16 (\i61 -> (imap1 4 (\i62 -> (imap1 4 (\i63 -> x4[i60][i61][((i62 * 4) + i63)]))))))))
in (let x8 = (imap1 5 (\i64 -> (imap1 16 (\i65 -> (imap1 4 (\i66 -> (imap1 4 (\i67 -> x5[i64][i65][((i66 * 4) + i67)]))))))))
in (let x9 = (imap1 5 (\i68 -> (imap1 4 (\i69 -> (imap1 16 (\i70 -> (imap1 4 (\i71 -> x6[i68][i70][i69][i71]))))))))
in (let x10 = (imap1 5 (\i72 -> (imap1 4 (\i73 -> (imap1 16 (\i74 -> (imap1 4 (\i75 -> x7[i72][i74][i73][i75]))))))))
in (let x11 = (imap1 5 (\i76 -> (imap1 4 (\i77 -> (imap1 16 (\i78 -> (imap1 4 (\i79 -> x8[i76][i78][i77][i79]))))))))
in (let x12 = (imap1 5 (\i80 -> (imap1 4 (\i81 -> (let x82 = (imap1 16 (\i84 -> (let x86 = (isoftmax1 16 (\i85 -> (((isum1 4 (\i88 -> (x9[i80][i81][i84][i88] F.* x10[i80][i81][i85][i88]))) F./ fromi64 2) F.+ mask[i84][i85])))
in (imap1 16 (\i87 -> x86[i87])))))
in (imap1 16 (\i83 -> (imap1 4 (\i90 -> (isum1 16 (\i91 -> (x82[i83][i91] F.* x11[i80][i81][i91][i90]))))))))))))
in (let x13 = (imap1 5 (\i92 -> (imap1 16 (\i93 -> (imap1 4 (\i94 -> (imap1 4 (\i95 -> x12[i92][i94][i93][i95]))))))))
in (let x14 = (imap1 5 (\i96 -> (imap1 16 (\i97 -> (imap1 16 (\i98 -> x13[i96][i97][(i98 / 4)][(i98 % 4)]))))))
in (let x15 = (imap1 5 (\i99 -> (imap1 16 (\i100 -> (imap1 16 (\i101 -> (isum1 16 (\i102 -> (wo[i101][i102] F.* x14[i99][i100][i102])))))))))
in (let x16 = (imap3 5 16 16 (\i103 i104 i105 -> (x1[i103][i104][i105] F.+ x15[i103][i104][i105])))
in (let x17 = (imap1 5 (\i106 -> (imap1 16 (\i107 -> (let x108 = (imap1 16 (\i112 -> (x16[i106][i107][i112] F.* x16[i106][i107][i112])))
in (let x109 = ((isum1 16 (\i113 -> x108[i113])) F./ fromi64 16)
in (let x110 = (F.sqrt (x109 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i111 -> (x16[i106][i107][i111] F.* (one F./ x110)))))))))))
in (let x18 = (imap1 5 (\i114 -> (imap1 16 (\i115 -> (imap1 64 (\i116 -> (isum1 16 (\i117 -> (wu[i116][i117] F.* x17[i114][i115][i117])))))))))
in (let x19 = (imap3 5 16 64 (\i118 i119 i120 -> (F.max x18[i118][i119][i120] zero)))
in (let x20 = (let x121 = (imap1 5 (\i124 -> (imap1 16 (\i125 -> (imap1 16 (\i126 -> (isum1 64 (\i127 -> (wd[i126][i127] F.* x19[i124][i125][i127])))))))))
in (let x122 = (imap3 5 16 16 (\i128 i129 i130 -> (x16[i128][i129][i130] F.+ x121[i128][i129][i130])))
in (imap1 5 (\i123 -> (imap1 16 (\i131 -> (imap1 27 (\i132 -> (isum1 16 (\i133 -> (wc[i132][i133] F.* x122[i123][i131][i133])))))))))))
in (let x21 = (imap3 5 16 27 (\i134 i135 i136 -> (target[i134][i135][i136] F.* (F.neg (F.log (let x138 = (isoftmax1 27 (\i137 -> x20[i134][i135][i137]))
in x138[i136]))))))
in ((isum3 5 16 27 (\i22 i23 i24 -> x21[i22][i23][i24])) F./ fromi64 80)))))))))))))))))))))))


def grad : (mask: [16][16]real)
  -> (wp: [16][16]real)
  -> (wqry: [16][16]real)
  -> (wkey: [16][16]real)
  -> (wval: [16][16]real)
  -> (wo: [16][16]real)
  -> (wu: [64][16]real)
  -> (wd: [16][64]real)
  -> (wc: [27][16]real)
  -> (ws: [5][16][16]real)
  -> (target: [5][16][27]real)
  ->
  (
    [5][16][16]real, --ws
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
  (wc: [27][16]real) (ws: [5][16][16]real) (target: [5][16][27]real) ->

let x0 = (let x1 = (imap1 5 (\i24 -> (imap2 16 16 (\i25 i26 -> (wp[i25][i26] F.+ ws[i24][i25][i26])))))
in (let x2 = (imap1 5 (\i27 -> (imap1 16 (\i28 -> (let x29 = ((isum1 16 (\i32 -> (x1[i27][i28][i32] F.* x1[i27][i28][i32]))) F./ fromi64 16)
in (let x30 = (F.sqrt (x29 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i31 -> (x1[i27][i28][i31] F.* (one F./ x30))))))))))
in (let x3 = (imap1 5 (\i33 -> (imap1 16 (\i34 -> (let x35 = ((isum1 16 (\i38 -> (x2[i33][i34][i38] F.* x2[i33][i34][i38]))) F./ fromi64 16)
in (let x36 = (F.sqrt (x35 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i37 -> (x2[i33][i34][i37] F.* (one F./ x36))))))))))
in (let x4 = (imap1 5 (\i39 -> (imap1 16 (\i40 -> (imap1 16 (\i41 -> (isum1 16 (\i42 -> (wqry[i41][i42] F.* x3[i39][i40][i42])))))))))
in (let x5 = (imap1 5 (\i43 -> (imap1 16 (\i44 -> (imap1 16 (\i45 -> (isum1 16 (\i46 -> (wkey[i45][i46] F.* x3[i43][i44][i46])))))))))
in (let x6 = (imap1 5 (\i47 -> (imap1 16 (\i48 -> (imap1 16 (\i49 -> (isum1 16 (\i50 -> (wval[i49][i50] F.* x3[i47][i48][i50])))))))))
in (let x7 = (imap1 5 (\i51 -> (imap1 16 (\i52 -> (imap1 4 (\i53 -> (imap1 4 (\i54 -> x4[i51][i52][((i53 * 4) + i54)]))))))))
in (let x8 = (imap1 5 (\i55 -> (imap1 16 (\i56 -> (imap1 4 (\i57 -> (imap1 4 (\i58 -> x5[i55][i56][((i57 * 4) + i58)]))))))))
in (let x9 = (imap1 5 (\i59 -> (imap1 16 (\i60 -> (imap1 4 (\i61 -> (imap1 4 (\i62 -> x6[i59][i60][((i61 * 4) + i62)]))))))))
in (let x10 = (imap1 5 (\i63 -> (imap1 4 (\i64 -> (imap1 16 (\i65 -> (imap1 4 (\i66 -> x7[i63][i65][i64][i66]))))))))
in (let x11 = (imap1 5 (\i67 -> (imap1 4 (\i68 -> (imap1 16 (\i69 -> (imap1 4 (\i70 -> x8[i67][i69][i68][i70]))))))))
in (let x12 = (imap1 5 (\i71 -> (imap1 4 (\i72 -> (imap1 16 (\i73 -> (imap1 4 (\i74 -> x9[i71][i73][i72][i74]))))))))
in (let x13 = (imap1 5 (\i75 -> (imap1 4 (\i76 -> (let x77 = (imap1 16 (\i79 -> (let x81 = (isoftmax1 16 (\i80 -> (((isum1 4 (\i83 -> (x10[i75][i76][i79][i83] F.* x11[i75][i76][i80][i83]))) F./ fromi64 2) F.+ mask[i79][i80])))
in (imap1 16 (\i82 -> x81[i82])))))
in (imap1 16 (\i78 -> (imap1 4 (\i85 -> (isum1 16 (\i86 -> (x77[i78][i86] F.* x12[i75][i76][i86][i85]))))))))))))
in (let x14 = (imap1 5 (\i87 -> (imap1 16 (\i88 -> (imap1 4 (\i89 -> (imap1 4 (\i90 -> x13[i87][i89][i88][i90]))))))))
in (let x15 = (imap1 5 (\i91 -> (imap1 16 (\i92 -> (imap1 16 (\i93 -> x14[i91][i92][(i93 / 4)][(i93 % 4)]))))))
in (let x16 = (imap1 5 (\i94 -> (imap1 16 (\i95 -> (imap1 16 (\i96 -> (isum1 16 (\i97 -> (wo[i96][i97] F.* x15[i94][i95][i97])))))))))
in (let x17 = (imap3 5 16 16 (\i98 i99 i100 -> (x2[i98][i99][i100] F.+ x16[i98][i99][i100])))
in (let x18 = (imap1 5 (\i101 -> (imap1 16 (\i102 -> (let x103 = ((isum1 16 (\i106 -> (x17[i101][i102][i106] F.* x17[i101][i102][i106]))) F./ fromi64 16)
in (let x104 = (F.sqrt (x103 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i105 -> (x17[i101][i102][i105] F.* (one F./ x104))))))))))
in (let x19 = (imap1 5 (\i107 -> (imap1 16 (\i108 -> (imap1 64 (\i109 -> (isum1 16 (\i110 -> (wu[i109][i110] F.* x18[i107][i108][i110])))))))))
in (let x20 = (imap3 5 16 64 (\i111 i112 i113 -> (F.max x19[i111][i112][i113] zero)))
in (let x21 = (imap1 5 (\i114 -> (imap1 16 (\i115 -> (imap1 16 (\i116 -> (isum1 64 (\i117 -> (wd[i116][i117] F.* x20[i114][i115][i117])))))))))
in (let x22 = (imap3 5 16 16 (\i118 i119 i120 -> (x17[i118][i119][i120] F.+ x21[i118][i119][i120])))
in (imap1 5 (\i23 -> (imap1 16 (\i121 -> (imap1 27 (\i122 -> (isum1 16 (\i123 -> (wc[i122][i123] F.* x22[i23][i121][i123])))))))))))))))))))))))))))))))
let x124 = (imap3 5 16 27 (\i125 i126 i127 -> (one F./ fromi64 80)))
let x128 = (imap1 5 (\i129 -> (imap1 16 (\i130 -> (let x132 = (isoftmax1 27 (\i131 -> x0[i129][i130][i131]))
in (imap1 27 (\i133 -> x132[i133])))))))
let x134 = (imap1 5 (\i135 -> (imap1 16 (\i136 -> (imap1 27 (\i139 -> (F.neg ((target[i135][i136][i139] F.* x124[i135][i136][i139]) F.* (one F./ (let x138 = (isoftmax1 27 (\i137 -> x0[i135][i136][i137]))
in x138[i139]))))))))))
let x140 = (imap1 5 (\i141 -> (imap1 16 (\i142 -> (isum1 27 (\i143 -> (x134[i141][i142][i143] F.* x128[i141][i142][i143])))))))
let x144 = (imap1 5 (\i145 -> (imap1 16 (\i146 -> (imap1 27 (\i147 -> (x128[i145][i146][i147] F.* (x134[i145][i146][i147] F.+ (F.neg x140[i145][i146])))))))))
let x148 = (imap1 5 (\i149 -> (imap2 16 16 (\i150 i151 -> (wp[i150][i151] F.+ ws[i149][i150][i151])))))
let x152 = (imap1 5 (\i153 -> (imap1 16 (\i154 -> (let x155 = ((isum1 16 (\i158 -> (x148[i153][i154][i158] F.* x148[i153][i154][i158]))) F./ fromi64 16)
in (let x156 = (F.sqrt (x155 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i157 -> (x148[i153][i154][i157] F.* (one F./ x156))))))))))
let x159 = (imap1 5 (\i160 -> (imap1 16 (\i161 -> (let x162 = ((isum1 16 (\i165 -> (x152[i160][i161][i165] F.* x152[i160][i161][i165]))) F./ fromi64 16)
in (let x163 = (F.sqrt (x162 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i164 -> (x152[i160][i161][i164] F.* (one F./ x163))))))))))
let x166 = (imap1 5 (\i167 -> (imap1 16 (\i168 -> (imap1 16 (\i169 -> (isum1 16 (\i170 -> (wqry[i169][i170] F.* x159[i167][i168][i170])))))))))
let x171 = (imap1 5 (\i172 -> (imap1 16 (\i173 -> (imap1 16 (\i174 -> (isum1 16 (\i175 -> (wkey[i174][i175] F.* x159[i172][i173][i175])))))))))
let x176 = (imap1 5 (\i177 -> (imap1 16 (\i178 -> (imap1 16 (\i179 -> (isum1 16 (\i180 -> (wval[i179][i180] F.* x159[i177][i178][i180])))))))))
let x181 = (imap1 5 (\i182 -> (imap1 16 (\i183 -> (imap1 4 (\i184 -> (imap1 4 (\i185 -> x166[i182][i183][((i184 * 4) + i185)]))))))))
let x186 = (imap1 5 (\i187 -> (imap1 16 (\i188 -> (imap1 4 (\i189 -> (imap1 4 (\i190 -> x171[i187][i188][((i189 * 4) + i190)]))))))))
let x191 = (imap1 5 (\i192 -> (imap1 16 (\i193 -> (imap1 4 (\i194 -> (imap1 4 (\i195 -> x176[i192][i193][((i194 * 4) + i195)]))))))))
let x196 = (imap1 5 (\i197 -> (imap1 4 (\i198 -> (imap1 16 (\i199 -> (imap1 4 (\i200 -> x181[i197][i199][i198][i200]))))))))
let x201 = (imap1 5 (\i202 -> (imap1 4 (\i203 -> (imap1 16 (\i204 -> (imap1 4 (\i205 -> x186[i202][i204][i203][i205]))))))))
let x206 = (imap1 5 (\i207 -> (imap1 4 (\i208 -> (imap1 16 (\i209 -> (imap1 4 (\i210 -> x191[i207][i209][i208][i210]))))))))
let x211 = (imap1 5 (\i212 -> (imap1 4 (\i213 -> (let x214 = (imap1 16 (\i216 -> (let x218 = (isoftmax1 16 (\i217 -> (((isum1 4 (\i220 -> (x196[i212][i213][i216][i220] F.* x201[i212][i213][i217][i220]))) F./ fromi64 2) F.+ mask[i216][i217])))
in (imap1 16 (\i219 -> x218[i219])))))
in (imap1 16 (\i215 -> (imap1 4 (\i222 -> (isum1 16 (\i223 -> (x214[i215][i223] F.* x206[i212][i213][i223][i222]))))))))))))
let x224 = (imap1 5 (\i225 -> (imap1 16 (\i226 -> (imap1 4 (\i227 -> (imap1 4 (\i228 -> x211[i225][i227][i226][i228]))))))))
let x229 = (imap1 5 (\i230 -> (imap1 16 (\i231 -> (imap1 16 (\i232 -> x224[i230][i231][(i232 / 4)][(i232 % 4)]))))))
let x233 = (imap1 5 (\i234 -> (imap1 16 (\i235 -> (imap1 16 (\i236 -> (isum1 16 (\i237 -> (wo[i236][i237] F.* x229[i234][i235][i237])))))))))
let x238 = (imap3 5 16 16 (\i239 i240 i241 -> (x152[i239][i240][i241] F.+ x233[i239][i240][i241])))
let x242 = (imap1 5 (\i243 -> (imap1 16 (\i244 -> (let x245 = ((isum1 16 (\i248 -> (x238[i243][i244][i248] F.* x238[i243][i244][i248]))) F./ fromi64 16)
in (let x246 = (F.sqrt (x245 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i247 -> (x238[i243][i244][i247] F.* (one F./ x246))))))))))
let x249 = (imap1 5 (\i250 -> (imap1 16 (\i251 -> (imap1 64 (\i252 -> (isum1 16 (\i253 -> (wu[i252][i253] F.* x242[i250][i251][i253])))))))))
let x254 = (imap3 5 16 64 (\i255 i256 i257 -> (F.max x249[i255][i256][i257] zero)))
let x258 = (imap1 5 (\i259 -> (imap1 16 (\i260 -> (imap1 16 (\i261 -> (isum1 64 (\i262 -> (wd[i261][i262] F.* x254[i259][i260][i262])))))))))
let x263 = (imap3 5 16 16 (\i264 i265 i266 -> (x238[i264][i265][i266] F.+ x258[i264][i265][i266])))
let x267 = (imap1 5 (\i268 -> (imap1 16 (\i269 -> (imap1 16 (\i270 -> (isum1 27 (\i271 -> (wc[i271][i270] F.* x144[i268][i269][i271])))))))))
let x272 = (imap1 5 (\i273 -> (imap1 16 (\i274 -> (imap1 64 (\i275 -> (isum1 16 (\i276 -> (wd[i276][i275] F.* x267[i273][i274][i276])))))))))
let x277 = (imap3 5 16 64 (\i278 i279 i280 -> ((indicatorp x249[i278][i279][i280]) F.* x272[i278][i279][i280])))
let x281 = (imap1 5 (\i282 -> (imap1 16 (\i283 -> (imap1 16 (\i284 -> (isum1 64 (\i285 -> (wu[i285][i284] F.* x277[i282][i283][i285])))))))))
let x286 = (imap1 5 (\i287 -> (imap1 16 (\i288 -> (imap1 16 (\i289 -> (x238[i287][i288][i289] F.* x238[i287][i288][i289])))))))
let x290 = (imap1 5 (\i291 -> (imap1 16 (\i292 -> ((isum1 16 (\i293 -> x286[i291][i292][i293])) F./ fromi64 16)))))
let x294 = (imap1 5 (\i295 -> (imap1 16 (\i296 -> (F.sqrt (x290[i295][i296] F.+ (one F./ fromi64 100000)))))))
let x297 = (imap1 5 (\i298 -> (imap1 16 (\i299 -> (F.neg ((one F./ x294[i298][i299]) F.* ((isum1 16 (\i300 -> (x238[i298][i299][i300] F.* x281[i298][i299][i300]))) F.* (one F./ x294[i298][i299]))))))))
let x301 = (imap1 5 (\i302 -> (imap1 16 (\i303 -> (x297[i302][i303] F.* (one F./ ((one F.+ one) F.* (F.sqrt (x290[i302][i303] F.+ (one F./ fromi64 100000))))))))))
let x304 = (imap1 5 (\i305 -> (imap1 16 (\i306 -> (imap1 16 (\i307 -> (x301[i305][i306] F./ fromi64 16)))))))
let x308 = (imap1 5 (\i309 -> (imap1 16 (\i310 -> (imap1 16 (\i311 -> (x267[i309][i310][i311] F.+ (((x281[i309][i310][i311] F.* (one F./ x294[i309][i310])) F.+ (x238[i309][i310][i311] F.* x304[i309][i310][i311])) F.+ (x304[i309][i310][i311] F.* x238[i309][i310][i311])))))))))
let x312 = (imap1 5 (\i313 -> (imap1 16 (\i314 -> (imap1 16 (\i315 -> (isum1 16 (\i316 -> (wo[i316][i315] F.* x308[i313][i314][i316])))))))))
let x317 = (imap1 5 (\i318 -> (imap1 16 (\i319 -> (imap1 4 (\i320 -> (imap1 4 (\i321 -> x312[i318][i319][((i320 * 4) + i321)]))))))))
let x322 = (imap1 5 (\i323 -> (imap1 4 (\i324 -> (imap1 16 (\i325 -> (imap1 4 (\i326 -> x317[i323][i325][i324][i326]))))))))
let x327 = (imap1 5 (\i328 -> (imap1 4 (\i329 -> (imap1 16 (\i330 -> (let x332 = (isoftmax1 16 (\i331 -> (((isum1 4 (\i334 -> (x196[i328][i329][i330][i334] F.* x201[i328][i329][i331][i334]))) F./ fromi64 2) F.+ mask[i330][i331])))
in (imap1 16 (\i333 -> x332[i333])))))))))
let x336 = (imap1 5 (\i337 -> (imap1 4 (\i338 -> (imap1 16 (\i339 -> (imap1 16 (\i340 -> (isum1 4 (\i341 -> (x322[i337][i338][i339][i341] F.* x206[i337][i338][i340][i341])))))))))))
let x342 = (imap1 5 (\i343 -> (imap1 4 (\i344 -> (imap1 16 (\i345 -> (imap1 16 (\i346 -> x336[i343][i344][i345][i346]))))))))
let x347 = (imap1 5 (\i348 -> (imap1 4 (\i349 -> (imap1 16 (\i350 -> (isum1 16 (\i351 -> (x342[i348][i349][i350][i351] F.* x327[i348][i349][i350][i351])))))))))
let x352 = (imap1 5 (\i353 -> (imap1 4 (\i354 -> (imap1 16 (\i355 -> (imap1 4 (\i356 -> (isum1 16 (\i357 -> (x327[i353][i354][i357][i355] F.* x322[i353][i354][i357][i356])))))))))))
let x358 = (imap1 5 (\i359 -> (imap1 4 (\i360 -> (imap1 16 (\i361 -> (imap1 4 (\i362 -> (isum1 16 (\i363 -> (x196[i359][i360][i363][i362] F.* ((x327[i359][i360][i363][i361] F.* (x342[i359][i360][i363][i361] F.+ (F.neg x347[i359][i360][i363]))) F./ fromi64 2))))))))))))
let x364 = (imap1 5 (\i365 -> (imap1 4 (\i366 -> (imap1 16 (\i367 -> (imap1 4 (\i368 -> (isum1 16 (\i369 -> (((x327[i365][i366][i367][i369] F.* (x342[i365][i366][i367][i369] F.+ (F.neg x347[i365][i366][i367]))) F./ fromi64 2) F.* x201[i365][i366][i369][i368])))))))))))
let x370 = (imap1 5 (\i371 -> (imap1 16 (\i372 -> (imap1 4 (\i373 -> (imap1 4 (\i374 -> x352[i371][i373][i372][i374]))))))))
let x375 = (imap1 5 (\i376 -> (imap1 16 (\i377 -> (imap1 4 (\i378 -> (imap1 4 (\i379 -> x358[i376][i378][i377][i379]))))))))
let x380 = (imap1 5 (\i381 -> (imap1 16 (\i382 -> (imap1 4 (\i383 -> (imap1 4 (\i384 -> x364[i381][i383][i382][i384]))))))))
let x385 = (imap1 5 (\i386 -> (imap1 16 (\i387 -> (imap1 16 (\i388 -> x370[i386][i387][(i388 / 4)][(i388 % 4)]))))))
let x389 = (imap1 5 (\i390 -> (imap1 16 (\i391 -> (imap1 16 (\i392 -> x375[i390][i391][(i392 / 4)][(i392 % 4)]))))))
let x393 = (imap1 5 (\i394 -> (imap1 16 (\i395 -> (imap1 16 (\i396 -> x380[i394][i395][(i396 / 4)][(i396 % 4)]))))))
let x397 = (imap1 5 (\i398 -> (imap1 16 (\i399 -> (imap1 16 (\i400 -> (((isum1 16 (\i401 -> (wval[i401][i400] F.* x385[i398][i399][i401]))) F.+ (isum1 16 (\i402 -> (wkey[i402][i400] F.* x389[i398][i399][i402])))) F.+ (isum1 16 (\i403 -> (wqry[i403][i400] F.* x393[i398][i399][i403]))))))))))
let x404 = (imap1 5 (\i405 -> (imap1 16 (\i406 -> (imap1 16 (\i407 -> (x152[i405][i406][i407] F.* x152[i405][i406][i407])))))))
let x408 = (imap1 5 (\i409 -> (imap1 16 (\i410 -> ((isum1 16 (\i411 -> x404[i409][i410][i411])) F./ fromi64 16)))))
let x412 = (imap1 5 (\i413 -> (imap1 16 (\i414 -> (F.sqrt (x408[i413][i414] F.+ (one F./ fromi64 100000)))))))
let x415 = (imap1 5 (\i416 -> (imap1 16 (\i417 -> (F.neg ((one F./ x412[i416][i417]) F.* ((isum1 16 (\i418 -> (x152[i416][i417][i418] F.* x397[i416][i417][i418]))) F.* (one F./ x412[i416][i417]))))))))
let x419 = (imap1 5 (\i420 -> (imap1 16 (\i421 -> (x415[i420][i421] F.* (one F./ ((one F.+ one) F.* (F.sqrt (x408[i420][i421] F.+ (one F./ fromi64 100000))))))))))
let x422 = (imap1 5 (\i423 -> (imap1 16 (\i424 -> (imap1 16 (\i425 -> (x419[i423][i424] F./ fromi64 16)))))))
let x426 = (imap1 5 (\i427 -> (imap1 16 (\i428 -> (imap1 16 (\i429 -> (x308[i427][i428][i429] F.+ (((x397[i427][i428][i429] F.* (one F./ x412[i427][i428])) F.+ (x152[i427][i428][i429] F.* x422[i427][i428][i429])) F.+ (x422[i427][i428][i429] F.* x152[i427][i428][i429])))))))))
let x430 = (imap1 5 (\i431 -> (imap1 16 (\i432 -> (imap1 16 (\i433 -> (x148[i431][i432][i433] F.* x148[i431][i432][i433])))))))
let x434 = (imap1 5 (\i435 -> (imap1 16 (\i436 -> ((isum1 16 (\i437 -> x430[i435][i436][i437])) F./ fromi64 16)))))
let x438 = (imap1 5 (\i439 -> (imap1 16 (\i440 -> (F.sqrt (x434[i439][i440] F.+ (one F./ fromi64 100000)))))))
let x441 = (imap1 5 (\i442 -> (imap1 16 (\i443 -> (F.neg ((one F./ x438[i442][i443]) F.* ((isum1 16 (\i444 -> (x148[i442][i443][i444] F.* x426[i442][i443][i444]))) F.* (one F./ x438[i442][i443]))))))))
let x445 = (imap1 5 (\i446 -> (imap1 16 (\i447 -> (x441[i446][i447] F.* (one F./ ((one F.+ one) F.* (F.sqrt (x434[i446][i447] F.+ (one F./ fromi64 100000))))))))))
let x448 = (imap1 5 (\i449 -> (imap1 16 (\i450 -> (imap1 16 (\i451 -> (x445[i449][i450] F./ fromi64 16)))))))
let x452 = (imap1 5 (\i453 -> (imap1 16 (\i454 -> (imap1 16 (\i455 -> (((x426[i453][i454][i455] F.* (one F./ x438[i453][i454])) F.+ (x148[i453][i454][i455] F.* x448[i453][i454][i455])) F.+ (x448[i453][i454][i455] F.* x148[i453][i454][i455]))))))))

let dwp = (imap2 16 16 (\i457 i458 -> (isum1 5 (\i456 -> x452[i456][i457][i458]))))
let dwkey = (imap1 16 (\i459 -> (imap1 16 (\i460 -> (isum1 5 (\i461 -> (isum1 16 (\i462 -> (x389[i461][i462][i459] F.* x159[i461][i462][i460])))))))))
let dwqry = (imap1 16 (\i463 -> (imap1 16 (\i464 -> (isum1 5 (\i465 -> (isum1 16 (\i466 -> (x393[i465][i466][i463] F.* x159[i465][i466][i464])))))))))
let dwval = (imap1 16 (\i467 -> (imap1 16 (\i468 -> (isum1 5 (\i469 -> (isum1 16 (\i470 -> (x385[i469][i470][i467] F.* x159[i469][i470][i468])))))))))
let dwo = (imap1 16 (\i471 -> (imap1 16 (\i472 -> (isum1 5 (\i473 -> (isum1 16 (\i474 -> (x308[i473][i474][i471] F.* x229[i473][i474][i472])))))))))
-- let dmask = (imap1 16 (\i475 -> (imap1 16 (\i478 -> (isum1 5 (\i476 -> (isum1 4 (\i477 -> (x327[i476][i477][i475][i478] F.* (x342[i476][i477][i475][i478] F.+ (F.neg x347[i476][i477][i475])))))))))))
let dwu = (imap1 64 (\i479 -> (imap1 16 (\i480 -> (isum1 5 (\i481 -> (isum1 16 (\i482 -> (x277[i481][i482][i479] F.* x242[i481][i482][i480])))))))))
let dwd = (imap1 16 (\i483 -> (imap1 64 (\i484 -> (isum1 5 (\i485 -> (isum1 16 (\i486 -> (x267[i485][i486][i483] F.* x254[i485][i486][i484])))))))))
let dwc = (imap1 27 (\i487 -> (imap1 16 (\i488 -> (isum1 5 (\i489 -> (isum1 16 (\i490 -> (x144[i489][i490][i487] F.* x263[i489][i490][i488])))))))))
let dws = (imap1 5 (\i491 -> (imap2 16 16 (\i492 i493 -> x452[i491][i492][i493]))))
-- let dtarget = (imap3 5 16 27 (\i494 i495 i496 -> (x124[i494][i495][i496] F.* (F.neg (F.log (let x498 = (isoftmax1 27 (\i497 -> x0[i494][i495][i497]))
-- in x498[i496]))))))

in (dws, dwp, dwqry, dwkey, dwval, dwo, dwu, dwd, dwc)
}

module nn64 = nn f64

let bs : i64 = 5
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

entry forward (p : params) (tokens : [bs][sl]i64) (mask : [sl][sl]f64) : [bs][sl][vo]f64 =
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
        (ws   :> [5][16][16]f64)
              :> [bs][sl][vo]f64)

entry cal_target (tokens : [bs][sl]i64) : [bs][sl]i64 =
  imap2 bs sl (\i j -> if (j < sl - 1) then tokens[i][j + 1] else vo)

entry cal_target_mask (n : i64) (target : [bs][sl]i64) : [bs][sl][vo]f64 =
  imap3 bs sl vo (\i j k -> (if ((j < (n - 1)) && (target[i][j] == k)) then 1 else 0))

entry loss (dl : i64) (p : params) (tokens : [bs][sl]i64) (mask : [sl][sl]f64) : f64 =
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
        (ws     :> [5][16][16]f64)
        (target :> [5][16][27]f64)
                :> f64)

def grad (dl : i64) (p : params) (tokens : [bs][sl]i64) (mask : [sl][sl]f64) :
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
        (ws     :> [5][16][16]f64)
        (target :> [5][16][27]f64)
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

def cal_step (dl : i64) (p : params) (mp : params) (vp : params)
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

entry train [steps] (p : params) (mp : params) (vp : params)
  (masks : [steps][sl][sl]f64) (dls  : [steps]i64)
  (batches  : [steps][bs][sl]i64) =
  let (new_p, new_mp, new_vp) =
    loop (p', mp', vp') = (p, mp, vp)
    for step < steps do
      let dl = dls[step]
      let batch = batches[step]
      let mask = masks[step]
      let (p', mp', vp') = (cal_step dl p' mp' vp' batch mask step steps)
      in (p', mp', vp')
  in ((from_params new_p), (from_params new_mp), (from_params new_vp))

-- def cal_step_verbose (dl : i64) (p : params) (mp : params) (vp : params)
--   (batch : [bs][sl]i64) (mask : [sl][sl]f64)
--   (step : i64) steps :
--   (params,  params,  params , f64) =
--   let loss = loss dl p batch mask
--   -- cal gradient
--   let (dwt, dwp, dwqry, dwkey, dwval, dwo, dwu, dwd, dwc) =
--     grad dl p batch mask
--   let dp = to_params dwt dwp dwqry dwkey dwval dwo dwu dwd dwc
--   -- cal new model weights
--   let (p', mp', vp') =
--     adam_opt p mp vp dp step steps
--   in (p', mp', vp', loss)

-- entry train_verbose [steps] (p : params) (mp : params) (vp : params)
--   (masks : [steps][sl][sl]f64) (dls  : [steps]i64)
--   (batches  : [steps][bs][sl]i64) =
--   let losses = imap1 steps (\_ -> 0)
--   let (new_p, new_mp, new_vp, new_losses) =
--     loop (p', mp', vp', losses') = (p, mp, vp, losses)
--     for step < steps do
--       let dl = dls[step]
--       let batch = batches[step]
--       let mask = masks[step]
--       let (p', mp', vp', loss) = (cal_step_verbose dl p' mp' vp' batch mask step steps)
--       let losses' = copy losses' with [step] = loss
--       in (p', mp', vp', losses')
--   in ((from_params new_p), (from_params new_mp), (from_params new_vp), new_losses)

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