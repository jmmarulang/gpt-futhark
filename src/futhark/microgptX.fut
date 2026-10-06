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

  def imaximum2 : (m: i64) -> (n: i64) -> (i64 -> i64 -> real) -> real =
    \m n f -> F.maximum (imap1 m (\i -> imaximum1 n (f i)))

  def isoftmax1 (m: i64) (f : i64 -> real) : [m]real =
    let max = imaximum1 m f
    let exps = imap1 m (\x -> F.exp((f x) F.+ F.neg max))
    let scale = isum1 m (\x -> exps[x])
    in imap1 m (\x -> exps[x] F./ scale)

  def isoftmax2 (m: i64) (n: i64) (f : i64 -> i64 -> real) : [m][n]real =
    let max = imaximum2 m n f
    let exps = imap2 m n (\x y -> F.exp((f x y) F.+ F.neg max))
    let scale = isum2 m n (\x y -> exps[x][y])
    in imap2 m n (\x y -> exps[x][y] F./ scale)

  --==== 2d cases ====--
  def sum2d (a: [][]real) : real =
    sum (map sum a)

  --==== Logistics ====--
  def logistics : real -> real =
    \e -> one F./ (one F.+ F.exp (F.neg e))

  def sgnp : real -> real = \e -> F.sgn (F.max e zero)

  def indicatorp : real -> real = sgnp

  --==== This is the generated function. ====--

  #[unsafe]
  def forward_seq
    (wp: [16][16]real)
    (wkey: [4][4][16]real)
    (wqry: [4][4][16]real)
    (wval: [4][4][16]real)
    (wo: [16][16]real)
    (mask: [16][16]real)
    (wu: [64][16]real)
    (wd: [16][64]real)
    (wc: [27][16]real)
    (ws: [1][16][16]real) :
    [1][16][27]real =
(let x0 = (imap2 1 16 (\i18 i19 -> (imap1 16 (\i20 -> (ws[i18][i19][i20] F.+ wp[i19][i20])))))
in (let x1 = (imap2 1 16 (\i21 i22 -> (let x23 = (imap1 16 (\i27 -> (x0[i21][i22][i27] F.* x0[i21][i22][i27])))
in (let x24 = ((isum1 16 (\i28 -> x23[i28])) F./ fromi64 16)
in (let x25 = (F.sqrt (x24 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i26 -> (x0[i21][i22][i26] F.* (one F./ x25)))))))))
in (let x2 = (imap2 1 16 (\i29 i30 -> (let x31 = (imap1 16 (\i35 -> (x1[i29][i30][i35] F.* x1[i29][i30][i35])))
in (let x32 = ((isum1 16 (\i36 -> x31[i36])) F./ fromi64 16)
in (let x33 = (F.sqrt (x32 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i34 -> (x1[i29][i30][i34] F.* (one F./ x33)))))))))
in (let x3 = (imap2 1 4 (\i37 i38 -> (imap2 16 4 (\i39 i40 -> (isum1 16 (\i41 -> (wkey[i38][i40][i41] F.* x2[i37][i39][i41])))))))
in (let x4 = (imap2 1 4 (\i42 i43 -> (imap2 16 4 (\i44 i45 -> (isum1 16 (\i46 -> (wqry[i43][i45][i46] F.* x2[i42][i44][i46])))))))
in (let x5 = (imap2 1 4 (\i47 i48 -> (imap2 16 4 (\i49 i50 -> (isum1 16 (\i51 -> (wval[i48][i50][i51] F.* x2[i47][i49][i51])))))))
in (let x6 = (imap2 1 4 (\i52 i53 -> (imap2 16 16 (\i54 i55 -> (((isum1 4 (\i56 -> (x4[i52][i53][i54][i56] F.* x3[i52][i53][i55][i56]))) F./ fromi64 2) F.* mask[i54][i55])))))
in (let x7 = (imap2 1 4 (\i57 i58 -> (let x61 = (isoftmax2 16 16 (\i59 i60 -> x6[i57][i58][i59][i60]))
in (imap2 16 16 (\i62 i63 -> x61[i62][i63])))))
in (let x8 = (imap2 1 16 (\i64 i65 -> (imap1 16 (\i66 -> (isum1 16 (\i67 -> (x7[i64][(i66 / 4)][i65][i67] F.* x5[i64][(i66 / 4)][i67][(i66 % 4)])))))))
in (let x9 = (imap2 1 16 (\i68 i69 -> (imap1 16 (\i70 -> (isum1 16 (\i71 -> (wo[i70][i71] F.* x8[i68][i69][i71])))))))
in (let x10 = (imap3 1 16 16 (\i72 i73 i74 -> (x1[i72][i73][i74] F.+ x9[i72][i73][i74])))
in (let x11 = (imap2 1 16 (\i75 i76 -> (let x77 = (imap1 16 (\i81 -> (x10[i75][i76][i81] F.* x10[i75][i76][i81])))
in (let x78 = ((isum1 16 (\i82 -> x77[i82])) F./ fromi64 16)
in (let x79 = (F.sqrt (x78 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i80 -> (x10[i75][i76][i80] F.* (one F./ x79)))))))))
in (let x12 = (imap2 1 16 (\i83 i84 -> (imap1 64 (\i85 -> (isum1 16 (\i86 -> (wu[i85][i86] F.* x11[i83][i84][i86])))))))
in (let x13 = (imap3 1 16 64 (\i87 i88 i89 -> (F.max x12[i87][i88][i89] zero)))
in (let x14 = (imap2 1 16 (\i90 i91 -> (imap1 16 (\i92 -> (isum1 64 (\i93 -> (wd[i92][i93] F.* x13[i90][i91][i93])))))))
in (let x15 = (imap3 1 16 16 (\i94 i95 i96 -> (x10[i94][i95][i96] F.+ x14[i94][i95][i96])))
in (imap2 1 16 (\i16 i17 -> (imap1 27 (\i97 -> (isum1 16 (\i98 -> (wc[i97][i98] F.* x15[i16][i17][i98])))))))))))))))))))))))

}

module nn' = nn f64

type params = {
  wt:   [27][16]f64, -- token embeddings
  wp:   [16][16]f64, -- position embeddings
  wkey:  [4][4][16]f64, -- key weights
  wqry:  [4][4][16]f64, -- query weights
  wval:  [4][4][16]f64, -- value weights
  wo:  [16][16]f64, -- output weights
  wu:   [64][16]f64, -- MLP up-projection
  wd: [16][64]f64, -- MLP down-projection
  wc:  [27][16]f64  -- output projection
}

entry to_params (wt: [27][16]f64)  (wp: [16][16]f64)
    (wkey: [4][4][16]f64) (wqry: [4][4][16]f64) (wval: [4][4][16]f64)
    (wo: [16][16]f64) (wu: [64][16]f64) (wd: [16][64]f64)
    (wc: [27][16]f64) : params =
    {wt, wp, wkey, wqry, wval, wo, wu, wd, wc}

def from_params (p : params) :
  (
  [27][16]f64, -- token embeddings
  [16][16]f64, -- position embeddings
  [4][4][16]f64, -- key weights
  [4][4][16]f64, -- query weights
  [4][4][16]f64, -- value weights
  [16][16]f64, -- output weights
  [64][16]f64, -- MLP up-projection
  [16][64]f64, -- MLP down-projection
  [27][16]f64  -- output projection
  ) =
  let {wt, wp, wkey, wqry, wval, wo, wu, wd, wc} = p
  in (wt, wp, wkey, wqry, wval, wo, wu, wd, wc)

entry forward_seq (p : params) (tokens : [1][16]i64) (mask : [16][16]f64) : [1][16][27]f64 =
   let {wt, wp, wkey, wqry, wval, wo, wu, wd, wc} = p
   let ws = (imap3 1 16 16 (\i j k -> wt[tokens[i][j]][k]))
   in nn'.forward_seq wp wkey wqry wval wo mask wu wd wc ws

def cal_target (n : i64) (tokens : [16]i64) : [16][27]f64 =
  imap2 16 27 (\i j -> (if ((i < (n - 1)) && (tokens[i + 1] == j)) then 1 else 0))

entry zero_params : params =
  let wt = imap2 27 16 (\_ _ -> 0)
  let wp = imap2 16 16 (\_ _ -> 0)
  let wkey = imap3 4 4 16 (\_ _ _ -> 0)
  let wqry = imap3 4 4 16 (\_ _ _ -> 0)
  let wval = imap3 4 4 16 (\_ _ _ -> 0)
  let wo = imap2 16 16 (\_ _ -> 0)
  let wu = imap2 64 16 (\_ _ -> 0)
  let wd = imap2 16 64 (\_ _ -> 0)
  let wc = imap2 27 16 (\_ _ -> 0)
  in {wt, wp, wqry, wkey, wval, wo, wu, wd, wc}