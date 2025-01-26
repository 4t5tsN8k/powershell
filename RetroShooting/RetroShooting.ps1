
function Shooting(){
	
# キー入力の取得ができるようにする
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Keyboard
{
	[DllImport("user32.dll")]
	public static extern short GetAsyncKeyState(int vKey);
}
"@

	# 仮想キー割り当て
	$VK_SPACE = 0x20 # SPACEキー
	$VK_LEFT = 0x25  # 左方向キー
	$VK_RIGHT = 0x27 # 右方向キー
	$VK_UP = 0x26 # 上方向キー
	$VK_4 = 0x34 # 4キー
	$VK_5 = 0x35 # 5キー
	$VK_6 = 0x36 # 6キー

	function KeyInput($keyinmode=0){

		$spacekey = $false
		$RL = 0
		$UD = 0

		if([Keyboard]::GetAsyncKeyState($VK_SPACE)) {
			$spacekey = $true
		}
		if($keyinmode -eq 0) {
			if([Keyboard]::GetAsyncKeyState($VK_LEFT)) {
				$RL = -1
			}
			if([Keyboard]::GetAsyncKeyState($VK_RIGHT)) {
				$RL = 1
			}
			if([Keyboard]::GetAsyncKeyState($VK_UP)) {
				$UD = -1
			}
		} else {
			if([Keyboard]::GetAsyncKeyState($VK_4)) {
				$RL = -1
			}
			if([Keyboard]::GetAsyncKeyState($VK_6)) {
				$RL = 1
			}
			if([Keyboard]::GetAsyncKeyState($VK_5)) {
				$UD = -1
			}
		}

		return $spacekey ,$RL ,$UD
	}

class ShipClass {

	$players = @() #自機情報配列　座標xy、状態、

	$framecnt = 0    # 移動回数　汎用カウンター

	# 定値固定値
	$EXPLOSION_CHAR = @(".","+","X") # 爆発表示
	$MAX_BEAM_CNT = 3 # ミサイルの最大数
    $ENEMYS_CORE = @{"Y"=60;"R"=50;"G"=30;} # Alienを撃ち落としたときの得点

	ShipClass(){
        $this.init()
	}

    [void] init() {

		$this.players = @{
			x = 20; # 座標x
			y = 14; # 座標y
			status = "alive"; # 状態 alive：通常、dead：無効、explosion：爆発中
			char = "@"; # 表示文字
			beams = @(); # ビームの座標配列 x,y
			score = 0; # 得点
			explosioncnt = 0; # 爆発表示用カウンター
			keyinmode = 0; # キー入力モード　0:カーソルキー　1:数字キー
		}

		$this.framecnt = 0
    }

	[void] setPos($x,$y) {

		$this.players.x = $x
		$this.players.y = $y
	}
	
	[void] move($screenWidth,$screenHeight) {
        $this.framecnt+=1

        # キー入力と自機の移動
		$spacekey ,$RL ,$UD = KeyInput($this.players.keyinmode)
		$this.players.x+=$RL
		if($this.players.x -eq 0) {
		   $this.players.x = 1
		}
		if($this.players.x -ge $screenWidth -1) {
		   $this.players.x = $screenWidth -1
		}

		# ミサイル発射
		if($UD -eq -1) {
			if($this.framecnt%2 -eq 0) {# 連射できないように2フレームごとに処理
				if($this.players.beams.length -lt $this.MAX_BEAM_CNT) {
					$this.players.beams+=@(@{x=$this.players.x;y=$this.players.y;char="!"})
				}
			}
		}

        # ミサイルの移動
		$tmp_beams=@()
		foreach($i in $this.players.beams){
			if($i.y -ge 2) {
				$tmp_beams+=@(@{x=$i.x;y=($i.y-1);char=$i.char})
			}	
		}
		$this.players.beams=@($tmp_beams)

		# 爆発表示
		if($this.players.status -eq "explosion") {
			if($this.players.explosioncnt -lt $this.EXPLOSION_CHAR.length) {
                $this.players.char = $this.EXPLOSION_CHAR[$this.players.explosioncnt]
    			$this.players.explosioncnt+=1
			} else {
				$this.players.status = "dead"
            }
		}

	}
	
	[void] draw($screen) {

		# 自機表示
		$screen.setCharacter($this.players.x,$this.players.y,$this.players.char)

		# ビーム表示
		foreach($i in $this.players.beams){
			$screen.setCharacter($i.x,$i.y,$i.char)
		}

	}

	[void] hitEnemy($aliens) {
		$tmp_score = 0

		foreach($i in $this.players.beams) {
			foreach($j in $aliens) {
				if($j.status -in ("alive","down") -and ($j.x -eq $i.x) -and ($j.y -eq $i.y)) { 
					$j.status = "explosion"
					$j.cnt = 0
					# 得点
					$tmp_score = $this.ENEMYS_CORE[($j.char)]
					if($j -eq "down") { # 降下中は得点が2倍になる
						$tmp_score*=2
					}
					# ミサイルy座標を1にして実質削除する
					$i.y = 1
					break
				}
			}
		}

		$this.players.score += $tmp_score
	}

	[Boolean] isPlayerDead(){
		if($this.players.status -eq "dead") {
			return $True
		} else {
			return $False
		}
	}

}

class EnemyClass {
	$base_x=0 # 集団の基本座標x
	$base_y=0 # 集団の基本座標y
	$base_dx=1 # 集団のx方向移動量

	$aliens = @() # alienの配列
		
    $aliencnt = 0 # 生きているalien数
    $downcnt = 0 # 降下中のalien数

	$missiles = @() # ミサイルの座標配列 x,y,

	$framecnt = 0 # 移動回数カウンター　処理の調整に使う

    # 定数固定値
	$MAX_LINES  = 4 # 集団の最大行数
	$MAX_COLUMS = 8 # 集団の最大列数
	$MAX_MISSILE_CNT = 10 # ミサイルの最大数
	$MAX_DOWN_CNT = 6 # 降下する最大数
    $ENEMY_CHAR = @("Y","R","G","G") #Alien表示キャラ　それぞれn列目
	$EXPLOSION_CHAR = @("+","X","."," ") # 爆発表示
	$MISSILE_CHAR = @("|","o") # ミサイル表示 直進する弾、誘導弾

	EnemyClass(){
		$this.init()
	}

	[void] init() {
		$this.base_x=2
		$this.base_y=3
		$this.base_dx=1
		$this.framecnt=0

		$this.missiles = @()
		$this.aliens = @()
		for($row=0;$row -lt $this.MAX_LINES;$row++) {
			for($col=0;$col -lt $this.MAX_COLUMS;$col++) {
				$this.aliens+=@( [ordered]@{
						x = ($this.base_x+($col * 3)) ; # 座標x,
						y = ($this.base_y + $row) ; # 座標y
						char = $this.ENEMY_CHAR[$row] ; # 表示キャラ
						status = "alive" ;  # 状態:alive：通常、dead：無効、down：降下中、explosion：爆発中、return：戻る
						dx = 0 ;  # x方向移動量
						dy = 0 ;  # y方向移動量
						cnt = 0 ; # 汎用カウンター
						shiptracking=$false ; # 降下中のSHIPを追跡するかどうか
						} )
			}
		}

		# 一部は非表示 1段目左右2匹 2段目左右1匹
		$this.aliens[0].status="dead"
		$this.aliens[1].status="dead"
		$this.aliens[3].status="dead"
		$this.aliens[4].status="dead"
		$this.aliens[6].status="dead"

		$this.aliens[7].status="dead"
		$this.aliens[8].status="dead"

		$this.aliens[15].status="dead"

        $this.aliencnt = ($this.aliens | where-object {$_.status -eq "alive"}).count

    }

	[void] move($screenWidth,$screenHeight,$players) {
        # 移動回数をカウントアップ
		$this.framecnt+=1

		$shipx = $players.x

        # ミサイルの移動処理
		for($i=0;$i -lt $this.missiles.length;$i++) {
			$dx=0
			if($this.missiles[$i].char -eq $this.MISSILE_CHAR[1] -and (($this.framecnt % 2) -eq 0)) {
				# SHIPを追跡するミサイル
				if($this.missiles[$i].x -lt $shipx) {
					$dx = 1
				} else {
					$dx = -1
				}
			}
			$this.missiles[$i] = @(@{x=($this.missiles[$i].x+$dx);y=($this.missiles[$i].y+1);char=$this.missiles[$i].char})
		}
		$this.missiles = $this.missiles | where-object{$_.y -le $screenHeight} # 画面外に出ていたら除外する

		# alienの移動処理は2フレームに一度にする
		if($this.framecnt % 2 -eq 0) { return }

		# 集団のx座標移動
		$this.base_x+=$this.base_dx

		$this.aliencnt = 0 #生きている数をリセット
		$this.downcnt = 0 #降下中の数をリセット

		for($row=0;$row -lt $this.MAX_LINES;$row++) {
			for($col=0;$col -lt $this.MAX_COLUMS;$col++) {
				$i = ($row*$this.MAX_COLUMS) + $col

				if($this.aliens[$i].status -eq "alive") {
					# 集団のalien

					# alienの数 カウントアップ
					$this.aliencnt+=1 

                    # x座標 移動
					$this.aliens[$i].x = $this.base_x + ($col * 3)
					$this.aliens[$i].y = $this.base_y + $row
					
					# 集団が端の壁にぶつかっていたら、次回から方向転換する
					if( $this.aliens[$i].x -ge ($screenWidth -1)){
						$this.aliens[$i].x = ($screenWidth -1)
						$this.base_dx = -1
					}
					if( $this.aliens[$i].x -le 1){
						$this.aliens[$i].x = 1
						$this.base_dx = 1
					}

				} elseif($this.aliens[$i].status -eq "down") {
					# 降下中のalien

					# alienの数 カウントアップ
					$this.aliencnt+=1

					# 降下中のalienの数 カウントアップ
					$this.downcnt+=1

					# 方向転換する処理
					$this.aliens[$i].cnt+=1
					if($this.aliens[$i].cnt -eq 3) {
						$this.aliens[$i].dx = 0 - $this.aliens[$i].dx
					}
					# SHIPを追跡する処理
					if($this.aliens[$i].cnt -gt 5 -and $this.aliens[$i].shiptracking -eq $True) {
						if($this.aliens[$i].x -eq $shipx) {
							$this.aliens[$i].dx = 0
						} elseif($this.aliens[$i].x -lt $shipx) {
							$this.aliens[$i].dx = 1
						} else {
							$this.aliens[$i].dx = -1
						}
					}

					# 座標計算
					$this.aliens[$i].x+=$this.aliens[$i].dx
					$this.aliens[$i].y+=$this.aliens[$i].dy

					#下の端にぶつかっていたら集団に戻る
					if($this.aliens[$i].y -gt $screenHeight ) {
						$this.aliens[$i].status = "return"
						$this.aliens[$i].x = $this.base_x + ($col * 3)
						$this.aliens[$i].y = 0
						$this.aliens[$i].cnt = 0
						$this.aliens[$i].shiptracking = $False
					}
					#端の壁にぶつかっていたら、次回から方向転換する
					if( $this.aliens[$i].x -ge ($screenWidth -1)){
						$this.aliens[$i].x = ($screenWidth -1)
						$this.aliens[$i].dx = -1
					} elseif( $this.aliens[$i].x -le 1){
						$this.aliens[$i].x = 1
						$this.aliens[$i].dx = 1
					}
				} elseif($this.aliens[$i].status -eq "explosion"){
					# 爆発中

					# 爆発アニメーションが終わったら消す
					if($this.aliens[$i].cnt -ge $this.EXPLOSION_CHAR.length-1){
						$this.aliens[$i].status = "dead"
					}

					# 爆発アニメーション
					$this.aliens[$i].char = $this.EXPLOSION_CHAR[$this.aliens[$i].cnt]

					$this.aliens[$i].cnt+=1
				} elseif($this.aliens[$i].status -eq "return") {
					# 集団へ帰還

					# alienの数 カウントアップ
					$this.aliencnt+=1
					  
					# 集団に戻るための移動
					# y座標が集団の位置になるまで降下する
					$this.aliens[$i].x = $this.base_x + ($col * 3)
					$this.aliens[$i].y += 1
					if($this.aliens[$i].y -eq ($row + $this.base_y)) {
						# 集団に戻る設定
						$this.aliens[$i].status = "alive"
					}

				}

				# ミサイル発射処理
				if($this.missiles.Length -lt $this.MAX_MISSILE_CNT) {
					if($this.aliens[$i].status -eq "alive") {
						$tmp_rand = Get-Random -Minimum 0 -Maximum 11
						if($tmp_rand -eq 0) {
							$this.missiles += @(@{x=$this.aliens[$i].x;y=$this.aliens[$i].y;char=$this.MISSILE_CHAR[0]})
						}
					} elseif($this.aliens[$i].status -eq "down" -and ($this.aliens[$i].y -lt $screenHeight-3)) {
						$tmp_rand = Get-Random -Minimum 0 -Maximum 11
						if($tmp_rand -in (0,1)) {
							$this.missiles += @(@{x=$this.aliens[$i].x;y=$this.aliens[$i].y;char=$this.MISSILE_CHAR[$tmp_rand]})
						}
					}
				}

			}
		}

	}

	# 降下するalienを決める処理
	[void] attacks() {
        
		if($this.framecnt % 8 -ne 0) { return }
		if($this.downcnt -ge $this.MAX_DOWN_CNT) { return }

		# 単独降下
		# 　ランダムで単独降下、エイリアンが6以下では毎回降下
		# 編隊降下
		# 　降下するalienは列の両サイドのエイリアンからランダムで決める。
		# 　編隊は真下と右下または左下のエイリアン3体
		# 　列の反対側のエイリアンが一緒に降下するバグがあるが自然に見えるのでそのままにする

		# エイリアンが6以下
		if($this.aliencnt -lt $this.MAX_DOWN_CNT){
			foreach($i in $this.aliens) {
				if($i.status -eq "alive") {
					# 毎回降下
					$i.status = "down"
					# 移動方向
					$i.dx = (Get-Random -Minimum 0 -Maximum 2)
					$i.dy = 1
					# 追跡するかどうかランダム
					$i.shiptracking = Get-Random -Minimum 0 -Maximum 2 | %{if($_ -eq 0){"$true"}else{"$False"}}
					# 降下中Alienカウンター
					$this.downcnt+=1
				}
			}
			return
		}

		# 降下するalienは列の両サイドのエイリアンからランダムで決める
		$downnum = $null
		$tmp_donwnumlist = @()
		$row = Get-Random -Minimum 0 -Maximum $this.MAX_LINES
		# 左から探す
		for($col=0;$col -lt $this.MAX_COLUMS;$col++) {
			$tmp_downnum = ($row*$this.MAX_COLUMS) + $col
			if($this.aliens[$tmp_downnum].status -eq "alive") {
				$tmp_donwnumlist += $tmp_downnum
				break
			} elseif($this.aliens[$tmp_downnum].status -eq "down") {
				break
			}
		}
		# 右から探す
		for($col=$this.MAX_COLUMS-1;$col -ge 0;$col--) {
			$tmp_downnum = ($row*$this.MAX_COLUMS) + $col
			if($this.aliens[$tmp_downnum].status -eq "alive") {
				$tmp_donwnumlist += $tmp_downnum
				break
			} elseif($this.aliens[$tmp_downnum].status -eq "down") {
				break
			}
		}

		$downnum = $tmp_donwnumlist | Get-Random

		# 見つからないときはリターン
		if($null -eq $downnum) {return}

		#移動方向の決定 
		if($downnum%$this.MAX_COLUMS -lt [int]($this.MAX_COLUMS/2)){
			$dirx = -1
			$downnum2 = $downnum + $this.MAX_COLUMS # 僚機は下
			$downnum3 = $downnum + $this.MAX_COLUMS - 1 # 僚機は左下
		} else {
			$dirx = 1
			$downnum2 = $downnum + $this.MAX_COLUMS # 僚機は下
			$downnum3 = $downnum + $this.MAX_COLUMS + 1 # 僚機は右下
		}

		#単独降下
		if($this.aliens[$downnum].status -eq "alive") {

			$this.aliens[$downnum].status = "down"
			$this.aliens[$downnum].dx = $dirx
			$this.aliens[$downnum].dy = 1

			# SHIPを追跡するかどうかランダムで決める
			$shiptracking = Get-Random -Minimum 0 -Maximum 2 | %{if($_ -eq 0){"$True"}else{"$False"}}
			$this.aliens[$downnum].shiptracking = $shiptracking

			$this.downcnt+=1

			#編隊降下
			if($this.aliens[$downnum2].status -eq "alive") {
				$this.aliens[$downnum2].status = "down"
				$this.aliens[$downnum2].dx = $dirx
				$this.aliens[$downnum2].dy = 1
				$this.aliens[$downnum2].shiptracking = $shiptracking
				$this.downcnt+=1
			}
			if($this.aliens[$downnum3].status -eq "alive") {
				$this.aliens[$downnum3].status = "down"
				$this.aliens[$downnum3].dx = $dirx
				$this.aliens[$downnum3].dy = 1
				$this.aliens[$downnum3].shiptracking = $shiptracking
				$this.downcnt+=1
			}
		}
	}

	[void] draw($screen) {
		foreach($i in $this.missiles) {
			$screen.setCharacter($i.x,$i.y,$i.char)
		}

		foreach($i in $this.aliens) {
			if($i.status -in ("alive","down","return","explosion")) {
			    if( $i.x -ge 1 -and $i.x -lt $screen.getScreenSizeX()-1) {
    			    $screen.setCharacter($i.x,$i.y,$i.char)
                }
			}
		}
	}
	
	[void] hitShip($players){
		if($players.status -ne "alive") {
			return 
		}

		$shipx = $players.x
		$shipy = $players.y

		# alienと自機の衝突
		foreach($i in $this.aliens) {
			if($i.x -eq $shipx -and $i.y -eq $shipy) {
				$players.status = "explosion"
				break
			}
		}

		# alienミサイルと自機の衝突
		foreach($i in $this.missiles) {
			if($i.x -eq $shipx -and $i.y -eq $shipy) {
				$players.status = "explosion"
				break
			}
		}
	}
	
}



class ScreenClass {
	$screen = @()
	
	ScreenClass(){
		$this.init()
	}
	
	[void] init(){
		$this.screen = @(
		"#########################################", # 00
		"#                                       #", # 01
		"#                                       #", # 02
		"#                                       #", # 03
		"#                                       #", # 04
		"#                                       #", # 05
		"#                                       #", # 06
		"#                                       #", # 07
		"#                                       #", # 08
		"#                                       #", # 09
		"#                                       #", # 10
		"#                                       #", # 11
		"#                                       #", # 12
		"#                                       #", # 13
		"#                                       #", # 14
		"#                                       #"  # 15
		#01234567890123456789012345678901234567890
		)
	}

	[int] getScreenSizeX() {
		return $this.screen[0].length
	}

	[int] getScreenSizeY() {
		return $this.screen.length
	}

	[void] setCharacter($x,$y,$char) {
        if($x -ge $this.screen[0].length -or $x -le 0) {
            return
        }
		$this.screen[$y]=$this.screen[$y].Remove($x,$char.length)
		$this.screen[$y]=$this.screen[$y].insert($x,$char)
	}

	[void] draw(){
		Clear-host
		foreach($i in $this.screen) {
			write-host $i
		}

<#
		# 色を付けるには
		foreach($i in $this.screen) {
			$tmp_index0 = 0
			$tmp_index = $i.indexOf("Y",$tmp_index0)
			while($tmp_index -ne -1) {
				write-host $i.Substring($tmp_index0,($tmp_index-$tmp_index0)) -NoNewline
				write-host $i[$tmp_index] -ForegroundColor Yellow -NoNewline
				$tmp_index0 = $tmp_index+1
				$tmp_index = $i.indexOf("Y",$tmp_index0)
			}

			write-host $i.Substring($tmp_index0)

		}

#>

	}

	[void] mask(){
		Clear-host
		for($i=0;$i -lt $this.screen.length;$i++) {
			for($j=0;$j -lt $this.screen[0].length;$j++) {
				write-host "#" -nonewline
			}
			write-host ""
			Start-Sleep -Milliseconds 50
		}
	}

	[void] demo($message){
		$message=@($message," START  SPACE  KEY ")
    	$message_y = [int]($this.screen.length / 2) - 1

		foreach($i in $message) {
			$message_x = [int]($this.screen[0].length / 2) - [int]($i.length /2 )
			$this.screen[$message_y]=$this.screen[$message_y].Remove($message_x ,$i.length)
			$this.screen[$message_y]=$this.screen[$message_y].insert($message_x ,$i)
			$message_y += 2
		}
		$this.draw()
	}

}

class game {
	$screen = $null # 画面表示クラス
	$ship = $null # 自機クラス
	$enemy = $null # 敵機クラス
	$status = "" # 状態 play:プレイ中 demo:デモモード
	$sleeptimer = 150 # Wait時間 ms


	game(){
		$this.screen = [ScreenClass]::new()
		$this.ship = [ShipClass]::new()
		$this.enemy = [EnemyClass]::new()
		$this.status= "demo"
		$this.sleeptimer = 150

		KeyInput
	}

	[void] start() {

		while($True) {
			if($this.status -eq "demo") {
				$this.demo()
			}
			if($this.status -eq "play"){
				$this.play()
			}
		}
	}

	[void] play(){

		$this.screen.init()
		$this.enemy.init()
		$this.ship.init()
		$this.ship.setPos( [int]($this.screen.getScreenSizeX()/2) , [int]($this.screen.getScreenSizeY()-2))

		$this.screen.mask()
		Start-Sleep -Milliseconds ($this.sleeptimer*3)

		while($this.status -eq "play"){
			$this.update()
			$this.hit()

			#終了処理
			if( $this.ship.isPlayerDead() -eq $True -or $this.enemy.aliencnt -le 0 ) {
				if($this.ship.isPlayerDead() -eq $True) {
					$message = "GAME OVER"
				} else {
					$message = "C L E A R"
				}

                $this.screen.demo($message)
				write-host "score = $($this.ship.players.score)" -ForegroundColor "White" -BackgroundColor "Red"
                Start-Sleep -Milliseconds 1000
				KeyInput #キー入力を初期化する

				$spacekey ,$RL ,$UD = KeyInput
				while(-not($spacekey) ) {
					$spacekey ,$RL,$UD  = KeyInput
				} 

				$this.status = "demo"
			}

			Start-Sleep -Milliseconds $this.sleeptimer
		}
	}

	# 移動と表示処理
	[void] update(){

		$this.screen.init()

		$this.ship.move($this.screen.getScreenSizeX()-1,$this.screen.getScreenSizeY()-1)
		$this.ship.draw($this.screen)
		$this.enemy.move($this.screen.getScreenSizeX()-1,$this.screen.getScreenSizeY()-1,$this.ship.players)
		$this.enemy.draw($this.screen)
		$this.enemy.attacks()

		$this.screen.draw()

		write-host "score = $($this.ship.players.score) alien = $($this.enemy.aliencnt)   < >..move ^..shot"
	}
	
	# 衝突判定
	[void] hit() {
		# alienとSHIP
		$this.enemy.hitShip($this.ship.players)
		# SHIPのミサイルとalien
		$this.ship.hitEnemy($this.enemy.aliens)
	}
	
	# デモンストレーションモード
	[void] demo() {
		$this.screen.init()
		$this.enemy.init()
		$this.ship.init()
		while($this.status -eq "demo"){
		
			$this.screen.init()
			$this.enemy.move($this.screen.getScreenSizeX()-1,$this.screen.getScreenSizeY()-1,$this.ship.players)
			$this.enemy.draw($this.screen)
    		$this.enemy.attacks()
			$this.screen.demo(" Galaxyan ")
			write-host "< >...move   ^...shot   space...start"
			
			Start-Sleep -Milliseconds $this.sleeptimer

			$spacekey ,$RL,$UD = KeyInput
			if($spacekey) {
				$this.status = "play"
			}
		}
		
	}
}

$game = $null
$game = [game]::new()
$game.start()

}

shooting

#作成ルール
- PowerShellでクラスを使うとPowerShell ISEでデバックできなくなるのでFunctionの中に入れる
- PowerShellには大文字小文字の区別が無い。このため大文字小文字を厳格に意識して作成しない
#命名規則
- クラス名：名詞＋CLASS　キャメルケースcamelCase
- 関数名：動詞＋名詞、動詞のみ
- 変数：xy座標とループカウンタ以外は2文字以上とする。端的な単語の連結とする
- 固定値変数：すべて大文字　スネークケースSNAKE_CASE
- 一時的な代入用変数：tmp_xxxとし、xxxには代入元変数名とする。またはtmp
- 関数の戻値変数：頭にres_xxxまたはres
- 引数：関数またはメソッドに引数を渡すとき受取側の変数名は渡す側と同じ名前とする　$this.x -> $x
- 主な略語：counter => cnt  character => char 
