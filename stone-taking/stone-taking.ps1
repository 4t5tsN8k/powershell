function stonetaking {
    write-host "＊＊＊＊＊＊＊＊"
    write-host "＊石取りゲーム＊"
    write-host "＊＊＊＊＊＊＊＊"
    write-host ""
    write-host "ルール"
    write-host "一列に並べられた20個の石があります。この石を先行後攻で交互に1～3個づつ取り"
    write-host "最後の1個を取った方が負けのゲームです"
    write-host ""
    write-host ""



    # 初期値
    $stone = "○●○●○●○●○●○●○●○●○●○●"
    $trun = -1 #0:コンピュータのターン 1:人のターン -1:未定
    $gemeflg = $True #ゲーム継続フラグ true:継続 false:終了

    # 先手後手の選択
    while($trun -lt 0 -or $trun -gt 1) {
        write-host ""
        $trun = read-host "先手後手どちらにしますか(1:先手　0:後手)"
        if($trun.Length -ne 1) {
            $trun = -1
        } elseif(($trun.Length -ne 1) -or ([int]::TryParse($trun,[ref]$null) -eq $False)) {
            $trun = -1
        }
    }
    if($trun -eq 1){
        write-host "あなたが先手です"
    } else {
        write-host "あなたが後手です"
    }
    write-host ""
    
    # コンピューターが拾う石の個数を考える処理
    function compturn {
        $resnum = 0
        #残りが奇数になるように取る
        if($stone.Length -eq 1){ # 石の残りが1個のとき
            $resnum = 1
        } elseif($stone.Length -eq 4){# 石の残りが4個以下のとき
            $resnum = 3
        } else {
            if($stone.Length % 2 -eq 0){ # 石の残り数が偶数のとき
                $resnum = 1
            } else { # 石の残り数が奇数のとき
                $resnum = 2            
            }
        }

        return $resnum
    }

    # 石を拾う処理
    function takestone($num){
        $res_stone = $stone
        for($i=0;$i -lt $num;$i++){
            if($res_stone.Length -eq 0){
                return $res_stone
            }
            $res_stone = $res_stone.Substring(0, $res_stone.Length - 1)
        }
        return $res_stone
    }

    write-host $stone

    while($gemeflg){
        $tack_stone=""
        if($trun -eq 0){ #コンピュータのターン
            $takecnt = compturn
            $stone = takestone($takecnt)
            write-host "comの番 $takecnt 個取りました"
            write-host "$stone"
            if($stone.Length -eq 0){
                write-host "comの負けです"
                $gemeflg = $False
            }
            $trun = 1 - $trun
        } else { # 人のターン
            $takecnt = -1
            while($takecnt -le 0 -or $takecnt -gt 3){
                write-host "あなたの番です"
                $takecnt = read-host "何個取りますか(1-3)"
                if($takecnt.Length -ne 1) {
                    $takecnt = -1
                } elseif(($takecnt.Length -ne 1) -or ([int]::TryParse($takecnt,[ref]$null) -eq $False)) {
                    $takecnt = -1
                }
            }
            write-host " $takecnt 個取りました"
            $stone = takestone($takecnt)
            write-host "$stone"
            if($stone.Length -eq 0){
                write-host "あなたの負けです"
                $gemeflg = $False
            }
            $trun = 1 - $trun
        }

        write-host ""

    }
}
