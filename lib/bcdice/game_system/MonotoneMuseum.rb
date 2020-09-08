# frozen_string_literal: true

require 'bcdice/dice_table/table'
require 'bcdice/dice_table/d66_range_table'
require 'bcdice/dice_table/d66_grid_table'
require 'bcdice/format'

module BCDice
  module GameSystem
    class MonotoneMuseum < Base
      # ゲームシステムの識別子
      ID = 'MonotoneMuseum'

      # ゲームシステム名
      NAME = 'モノトーンミュージアムRPG'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ものとおんみゆうしあむRPG'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・判定
        　・通常判定　　　　　　2D6+m>=t[c,f]
        　　修正値m,目標値t,クリティカル値c,ファンブル値fで判定ロールを行います。
        　　クリティカル値、ファンブル値は省略可能です。([]ごと省略できます)
        　　自動成功、自動失敗、成功、失敗を自動表示します。
        ・各種表
        　・感情表　ET／感情表 2.0　ET2
        　・兆候表　OT／兆候表ver2.0　OT2
        　・歪み表　DT／歪み表ver2.0　DT2／歪み表(野外)　DTO／歪み表(海)　DTS／歪み表(館・城)　DTM
        　・世界歪曲表　WDT／世界歪曲表2.0　WDT2
        　・永劫消失表　EDT
        ・D66ダイスあり
      INFO_MESSAGE_TEXT

      # ダイスボットを初期化する
      def initialize
        super

        # 式、出目ともに送信する

        # D66ダイスあり（出目をソートしない）
        @enabled_d66 = true
        @d66_sort_type = D66SortType::NO_SORT
        # バラバラロール（Bコマンド）でソートする
        @sort_add_dice = true
      end

      # 固有のダイスロールコマンドを実行する
      # @param [String] command 入力されたコマンド
      # @return [String, nil] ダイスロールコマンドの実行結果
      def rollDiceCommand(command)
        if (ret = check_roll(command))
          return ret
        end

        return roll_tables(command, TABLES)
      end

      private

      def check_roll(command)
        m = /^(\d+)D6([\+\-\d]*)>=(\d+)(\[(\d+)?(,(\d+))?\])?$/i.match(command)
        unless m
          return nil
        end

        dice_count = m[1].to_i
        modify_number = m[2] ? ArithmeticEvaluator.new.eval(m[2]) : 0
        target = m[3].to_i
        critical = (m[5] || 12).to_i
        fumble = (m[7] || 2).to_i

        dice_value, dice_str, = roll(dice_count, 6, @sort_add_dice)
        total = dice_value + modify_number

        result =
          if dice_value <= fumble
            "自動失敗"
          elsif dice_value >= critical
            "自動成功"
          elsif total >= target
            "成功"
          else
            "失敗"
          end

        sequence = [
          "(#{command})",
          "#{dice_value}[#{dice_str}]#{Format.modifier(modify_number)}",
          total.to_s,
          result,
        ]

        return sequence.join(" ＞ ")
      end

      # モノトーンミュージアム用のテーブル
      # D66を振って決定する
      # 1項目あたり出目2つに対応する
      class MMTable < DiceTable::D66RangeTable
        # @param name [String]
        # @param items [Array<String>]
        def initialize(name, items)
          if items.size != RANGE.size
            raise UnexpectedTableSize.new(name, items.size)
          end

          items_with_range = RANGE.zip(items)

          super(name, items_with_range)
        end

        # 1項目あたり2個
        RANGE = [11..12, 13..14, 15..16, 21..22, 23..24, 25..26, 31..32, 33..34, 35..36, 41..42, 43..44, 45..46, 51..52, 53..54, 55..56, 61..62, 63..64, 65..66].freeze
      end

      TABLES = {
        "ET" => DiceTable::D66GridTable.new(
          "感情表",
          [
            ["【信頼（しんらい）】", "【有為（ゆうい）】", "【友情（ゆうじょう）】", "【純愛（じゅんあい）】", "【慈愛（じあい）】", "【憧れ（あこがれ）】"],
            ["【恐怖（きょうふ）】", "【脅威（きょうい）】", "【憎悪（ぞうお）】", "【不快感（ふかいかん）】", "【食傷（しょくしょう）】", "【嫌悪（けんお）】"],
            ["【好意（こうい）】", "【庇護（ひご）】", "【遺志（いし）】", "【懐旧（かいきゅう）】", "【尽力（じんりょく）】", "【忠誠（ちゅうせい）】"],
            ["【不安（ふあん）】", "【侮蔑（ぶべつ）】", "【嫉妬（しっと）】", "【劣等感（れっとうかん）】", "【優越感（ゆうえつかん）】", "【憐憫（れんびん）】"],
            ["【尊敬（そんけい）】", "【感服（かんぷく）】", "【慕情（ぼじょう）】", "【同情（どうじょう）】", "【傾倒（けいとう）】", "【好奇心（こうきしん）】"],
            ["【偏愛（へんあい）】", "【執着（しゅうちゃく）】", "【悔悟（かいご）】", "【警戒心（けいかいしん）】", "【敵愾心（てきがいしん）】", "【忘却（ぼうきゃく）】"],
          ]
        ),
        "ET2" => DiceTable::D66GridTable.new(
          "感情表2.0",
          [
            ["【プレイヤーの任意】", "【同一視（どういつし）】", "【連帯感（れんたいかん）】", "【幸福感（こうふくかん）】", "【親近感（しんきんかん）】", "【誠意（せいい）】"],
            ["【懐旧（かいきゅう）】", "【同郷（どうきょう）】", "【同志（どうし）】", "【くされ縁（くされえん）】", "【期待（きたい）】", "【好敵手（こうてきしゅ）】"],
            ["【借り（かり）】", "【貸し（かし）】", "【献身（けんしん）】", "【義兄弟（ぎきょうだい）】", "【幼子（おさなご）】", "【親愛（しんあい）】"],
            ["【疎外感（そがいかん）】", "【恥辱（ちじょく）】", "【憐憫（れんびん）】", "【隔意（かくい）】", "【嫌悪（けんお）】", "【猜疑心（さいぎしん）】"],
            ["【厭気（けんき）】", "【不信感（ふしんかん）】", "【怨念（おんねん）】", "【悲哀（ひあい）】", "【悪意（あくい）】", "【殺意（さつい）】"],
            ["【敗北感（はいぼくかん）】", "【徒労感（とろうかん）】", "【黒い泥（くろいどろ）】", "【憤懣（ふんまん）】", "【無関心（むかんしん）】", "【プレイヤーの任意】"],
          ]
        ),
        "OT" => DiceTable::Table.new(
          "兆候表",
          "2D6",
          [
            "【信念の喪失】\n[出自]を喪失する。特徴は失われない。",
            "【昏倒】\nあなたは[戦闘不能]になる。",
            "【肉体の崩壊】\nあなたは2D6点のHPを失う。",
            "【放心】\nあなたはバッドステータスの[放心]を受ける。",
            "【重圧】\nあなたはバッドステータスの[重圧]を受ける。",
            "【現在の喪失】\n現在持っているパートナーをひとつ喪失する。",
            "【マヒ】\nあなたはバッドステータスの[マヒ]を受ける。",
            "【邪毒】\nあなたはバッドステータスの[邪毒]5を受ける。",
            "【色彩の喪失】\n漆黒、墨白、透明化……。その禍々しい色彩の喪失は他らなぬ異形化の片鱗だ。",
            "【理由の喪失】\n[境遇]を喪失する。特徴は失われない。",
            "【存在の喪失】\nあなたの存在は一瞬、この世界から消失する。",
          ]
        ),
        "DT" => DiceTable::Table.new(
          "歪み表",
          "2D6",
          [
            "【世界消失】\n演目の舞台がすべて失われる。舞台に残っているのはキミたちと異形、伽藍だけだ。クライマックスフェイズへ。",
            "【生命減少】\n演目の舞台となっている街や国から動物や人間の姿が少なくなる。特に子供の姿は見られない。",
            "【空間消失】\n演目の舞台の一部（建物一棟程度）が消失する。",
            "【天候悪化】\n激しい雷雨に見舞われる。",
            "【生命繁茂】\nシーン内に植物が爆発的に増加し、建物はイバラのトゲと蔓草に埋没する。",
            "【色彩喪失】\n世界から色彩が失われる。世界のすべてをモノクロームになったかのように認識する。",
            "【神権音楽】\n美しいが不安を覚える音が流れる。音は人々にストレスを与え、街の雰囲気は悪化している。",
            "【鏡面世界】\n演目の舞台に存在するあらゆる文字は鏡文字になる。",
            "【時空歪曲】\n昼夜が逆転する。昼間であれば夜になり、夜であれば朝となる。",
            "【存在修正】\nGMが任意に決定したNPCの性別や年齢、外見が変化する。",
            "【人体消失】\nシーンプレイヤーのパートナーとなっているNPCが消失する。どのNPCが消失するかは、GMが決定する。",
          ]
        ),
        "DT2" => MMTable.new(
          "歪み表ver2.0",
          [
            "【色彩侵食】\nシーン内に存在するあらゆる無生物と生物は、白と黒とのモノトーンの存在となる。紡ぎ手は【縫製】難易度8の判定に成功すれば、この影響を受けない。この効果は歪みをもたらした異形の死によって解除される。",
            "【虚無現出】\nほつれの中から虚無がしみ出す。シーンに登場しているエキストラは虫一匹にいたるまで消滅し、二度と現れない。",
            "【季節変容】\n季節が突如として変化する。1D6し、1なら春、2なら夏、3なら秋、4なら冬、5ならプレイしている現在の季節、6ならGMの任意とせよ。",
            "【ほつれ】\n世界がひび割れ、ほつれが現出する。ほつれに触れたものは虚無に飲み込まれ、帰ってくることはない。",
            "【異形化】\nシーン内のすべてのエキストラは何らかの異形化を受ける。これを治癒する術はない。異形の群れ（『IZ』P.237）×1D6と戦闘させてもよい。",
            "【死の行進】\n人々の心に虚無が広がり、不安と絶望に満たされていく。逃れられぬ恐怖から逃れようと、人々はみずから、あるいは無意識のうちに死へと向かい行動を始める。",
            "【時間加速】\nシーン内に存在するあらゆる無生物と生物は、2D6年ぶん時間が加速する。生物なら老化する。紡ぎ手は【縫製】難易度8の判定に成功すれば、この影響を受けない。",
            "【時間逆流】\nシーン内に存在するあらゆる無生物と生物は、2D6年ぶん時間が逆流する。生物ならば若返る。製造年／生年より前に戻った場合は虚無に飲まれ消滅する。紡ぎ手は【縫製】難易度8の判定に成功すれば、この影響を受けない。",
            "【災害到来】\n嵐、火山の噴火、洪水など、ほつれによって乱された自然が、人々に牙をむく。",
            "【人心荒廃】\n歪みによってもたらされた不安と恐怖は、人々を捨て鉢にさせる。",
            "【平穏無事】\n何も起きない。紡ぎ手は背筋が凍るほどの恐怖を覚える。",
            "【疫病蔓延】\n登場しているキャラクターは【肉体】難易度8の判定を行ない、失敗すると［邪毒］5を受ける。病の治療法の有無などについてはGMが決定する。迷ったら、伽藍を倒すと病も消滅する、とせよ。",
            "【異端審問】\n異端審問の時は近い。PCたちが紡ぎ手であることが知れ渡れば、PCたちも火刑台へと送られることになろう。",
            "【歪み出現】\nほつれの破片から歪みが現れ、人々を襲撃する。病魔（『IZ』P.238）×2と戦闘を行なわせてもよい。また、別の異形でもよい。",
            "【悪夢現出】\nシーン内のあらゆる人々は恐るべき恐怖の夢を見る。心弱きものたちは、伽藍にすがるか、異端者を火あぶりにせねばこの夢から逃れられぬと考えるだろう。",
            "【鼠の宴】\n鼠の大群が出現し、穀物を食い荒らし、疫病をまき散らす。大鼠（『MM』P.240）×1D6と戦闘を行なわせてもよい。",
            "【歪曲御標】\n歪んだ御標が下される。歪み表（『MM』P.263）を振ること。",
            "【地域消滅】\n演目の舞台となっている地域そのものが消えてなくなる。影響下にあるすべてのキャラクター（伽藍を含む）は【縫製】難易度10の判定に成功すれば脱出できる。失敗した場合即座に死亡する。エキストラは無条件で死亡する。",
          ]
        ),
        "WDT" => DiceTable::Table.new(
          "世界歪曲表",
          "2D6",
          [
            "【消失】\n世界からボスキャラクターが消去され、消滅する。エンディングフェイズへ。",
            "【自己犠牲】\nチャートを振ったPCのパートナーとなっているNPCのひとりが死亡する。チャートを振ったPCのHPとMPを完全に回復させる。",
            "【生命誕生】\nキミたちは大地の代わりに何かの生き物の臓腑の上に立っている。登場しているキャラクター全員に［邪毒］5を与える。",
            "【歪曲拡大】\nシーンに登場している紡ぎ手ではないNPCひとりが漆黒の凶獣（『MM』P.240）に変身する。",
            "【暴走】\n“ほつれ”がいくつも生まれ、シーンに登場しているすべてのキャラクターの剥離値を+1する。",
            "【幻像世界】\n周囲の空間は歪み、破壊的なエネルギーが充満する。次に行なわれるダメージロールに+5D6する。",
            "【変調】\n右は左に、赤は青に、上は下に、歪みが身体の動きを妨げる。登場しているキャラクター全員に［狼狽］を与える。",
            "【空間消失】\n演目の舞台が煙のように消失する。圧倒的な喪失感により、登場しているキャラクター全員に［放心］を与える。",
            "【生命消失】\n次のシーン以降、エキストラは一切登場できない。現在のシーンのエキストラに関してはGMが決定する。",
            "【自己死】\nもっとも剥離値の高いPCひとりが［戦闘不能］になる。複数のPCが該当した場合はGMがランダムに決定する。",
            "【世界死】\n世界の破滅。難易度12の【縫製】判定に成功すると破滅から逃れられる。失敗すると行方不明になる。エンディングフェイズへ。",
          ]
        ),
        "WDT2" => MMTable.new(
          "世界歪曲表ver2.0",
          [
            "【歪みの茨】\nシーン全体が鋼鉄よりも硬い茨の棘によって埋め尽くされる。飛行状態でないキャラクターは、移動を行う度に〈刺〉3D6+[そのシーンで登場するキャラクターの中で最大の演者レベル]点のダメージを受ける。",
            "【世界歪曲】\n世界歪曲表（『MM』P264）を振る。",
            "【さかさま世界】\n空か゛地面に、地面が空になる。そのシーン中、全ての飛行状態であるキャラクターは飛行状態でないものとして、飛行状態にないキャラクターは飛行状態として扱う。",
            "【海の記憶】\n存在するはずのない潮騒が聞こえ、世界の全てが波に飲み込まれる。このシーン中、飛行状態でない全てのキャラクターは水中状態として扱う。",
            "【空間湾曲】\n世界は歪む。こことあそこは意味を失う。このシーンの間、全てのキャラクターの移動力は∞となり、特技と装備の射程は全て「視界」となる。",
            "【濃霧世界】\nミルクよりも白く、濃厚な霧が世界を閉ざす。このシーンの間、特技と装備の射程が「視界」「6m以上」出会った場合、すべて「5m」に変更される。",
            "【豪雨】\nすさまじい雨が降る。雨は全ての人の心を凍らせる。このシーンの間、「種別：銃」である武器を用いた攻撃のファンブル値を+6する。また、別エンゲージへの物理攻撃の達成値を-2する。",
            "【どろどろ】\n足下がいつの間にか不定型な泥沼になっている。このシーンの間、飛行状態でないキャラクターが同一エンゲージに対して行う物理攻撃のファンブル値を+6する。",
            "【暴風】\n風は吹きすさび運命を嘲笑する。このシーンの間、飛行状態でないキャラクターが同一エンゲージに対して行う物理攻撃のファンブル値を+6する",
            "【魔法暴走】\n魔法の力は暴走し、もう誰の手にも負えない。世界は終わる。消えていく。このシーンの間、「種別：術」の特技を用いた判定のファンブル値は+6される",
            "【自己死】\n巨大なほつれが発生し、致命的なダメージを負う。最も剥離値の高いPCひとりが戦闘不能になる。複数のPCが該当した場合はGMがランダムに決定する",
            "【虚構の報い】\n紡ぎ手によってゆがめられ続けた因果が逆襲する。このシーンで《虚構現出》を使用した場合、代償に加えて10D6点の実ダメージを受ける。このダメージは軽減できず、移し替えることもできない。",
            "【虚構の果て】\n神が見捨てたのか、神を見捨てたのか。逸脱の果て、世界は終わる。あなたはこのシーンで逸脱能力を使用した場合、上昇した剥離値の10倍だけの実ダメージを受ける。このダメージは軽減できず、移し替えることも出来ない。",
            "【人格交代】\n魂、厳密には魂の背後にあるナニモノカが入れ替わる。左隣のプレイヤーにキャラクターシートを渡し、このシーン中はそのプレイヤーがあなたのPCを演じる。GMが認めれば、GMもNPCと入れ替えてもいい。",
            "【因果の糸】\n嗤う声がする。「逸脱の結果は共有しようよ？」PC全員の剥離値を平均し（端数切り上げ）、全員の剥離値をその計算結果に書き換える、",
            "【剣に斃る】\n人を裁く者に報いを、剣には剣の対価を。このシーンで攻撃を行いファンブルした場合、5D6点の実ダメージを受ける。",
            "【秘密暴露】\n隠しておきたい秘密を小鳥が囀り、リスが囁く。登場している全ての紡ぎ手、異形、伽藍は隠しておきたい秘密（そのキャラクターの主観で良い）ひとつを明らかにする。さもなければ、10D6点の実ダメージを受ける。このダメージは軽減も移し替えも出来ない。",
            "【荒廃の王】\n気がつくと全てのキャラクターは、虚ろの荒野の荒廃の王（『MM』p.212）の身体の飢えにいる。全てのキャラクターはその虚無に巻き込まれ、5D6点の実ダメージを受ける。このダメージは軽減も移し替えも出来ない。荒廃の王があなたたちにどのような影響をもたらすかはGMの任意とせよ。",
          ]
        ),
        "OT2" => MMTable.new(
          "兆候表ver2.0",
          [
            "【信念の喪失】\nあなたの精神があなたの過去を否定する。あなたは[出自]とそれにまつわる記憶をそのシーン中喪失する。特徴の効果は失われないが、其れを認識することは出来ない。",
            "【昏倒】\nもうあなたは逸脱の重さに耐えることは出来ない。これが世界に刃向かった報いだ。あなたは[戦闘不能]になる。すでに[戦闘不能]なら、[死亡]する。",
            "【肉体の崩壊】\n硝子の砕ける音がして、あなたも砕けていく。あなたは2D6+キャラクターレベル点の【HP】を失う。",
            "【放心】\nあなたの心に大きな衝動が襲いかかる。心は伽藍に向かって歪み、瞳は色のない悪夢を見る。あなたはバッドステータスの[放心]を受ける。",
            "【重圧】\nどこからかあなたを嘲笑する声がする。「こうして御標に背いた愚か者は、鎖に繋がれて責め苦を受けるのです」。あなたはバッドステータスの[重圧]を受ける。",
            "【現在の喪失】\n現在持っているパートナーをひとつ喪失する。あなたは何かを失ったことには気がつくが、その人物のことは思い出せない。この効果はその演目の間、継続する。もちろん、新しく人間関係を構築することも出来ない。",
            "【マヒ】\n異形化した肉体の変異に、魂が耐えられない。身体がしびれ、震えが止まらない。あなたはバッドステータスの[マヒ]を受ける。",
            "【邪毒】\n意識の深いところで異形化が進行し、あなたの肉体を蝕みはじめる。あなたはバッドステータスの[邪毒]5を受ける。",
            "【色彩の喪失】\nあなたの身体から色が消えて曇白へと近付いてゆく。服や化粧などで隠すことは出来るが、ばれれば異端尋問は免れまい。あなたの剥離値を+1D6する。（この効果では兆候表を振らない）",
            "【理由の喪失】\nあなたの精神があなたの現在を否定する。あなたは[境遇]とそれにまつわる記憶をそのシーン中喪失する。特徴の効果は失われないが、其れを認識することはできない。",
            "【存在の喪失】\nふいに、煙のようにあなたの姿がかき消えた。あなたの存在は一瞬、この世界から喪失する。あなたの剥離値を+1D6する。（この効果では兆候表を振らない）",
            "【逸脱の対価】\n逸脱能力を用いた結果この表を振ることになった場合にのみ適用する（そうでないなら振り直し）。この表を振る原因となった逸脱能力はこのラウンド（戦闘中でないならシーン）中はもはや使用できない。",
            "【逸脱の重責】\n世界から逸脱した結果、肉体が急激に異形化し身体を苛む。[上昇した剥離値×10]点の【HP】を失う。",
            "【急激な異形化】\n身体の一部（耳、指、瞳）などが歪んだ獣のそれになる。しかし、そのことはあなたの力ともなる。【HP】を（キャラクターレベル）D6点回復する（回復できない状態でも回復する）。あなたの剥離値を+2する（この効果では兆候表を振らない）。",
            "【精神の崩壊】\n身体が異形化し、世界から剥離していく。あなたの存在はぼやけてやがて消えていく。魂すらも。あなたは2D6+キャラクターレベル点の【MP】を失う。",
            "【逸脱の呪い】\n逸脱能力を用いた結果この表を振ることになった場合にのみ適用する（そうでないなら振り直し）。この表を振る原因となった逸脱能力は、この演目の間あなたが使用する場合、剥離値の上昇を2倍に数える。",
            "【剥離の伝播】\n世界の歪みは広がり、拡散し、誰も逃れられない。あなたの剥離値が、シーンに登場しているPCで最も剥離値の高いPCと同じになる。あなたが最も高いなら、最も低いPCの剥離値があなたと同じになる（複数登場している場合はランダムに選ぶこと）。",
            "【運命の恩寵】\n恩寵、あるいは悲劇への対価か。あなたは逸脱能力をその演目中に限り、更に一種類使用できるようになる（任意に選択せよ）。選択した逸脱能力の剥離値上昇は+1される。",
          ]
        ),
        "DTO" => MMTable.new(
          "歪み表(野外)",
          [
            "【死の蔓延】\n木は枯れて奇っ怪な姿になり、花はしおれる。大気は淀んだ腐敗臭を放ち、岩はねじくれる。すべてのものが死の気配に包まれる",
            "【歪曲御標】\n歪んだ御標が下される。歪み表（『MM』P263）を振ること。",
            "【季節変容】\n季節が突如として変化する。1D6し、1なら春、2なら夏、3なら秋、4なら冬、5なら四季が狂ったように変動し、6ならGMの任意とせよ。急激な季節の変化は、自然と人々の健康を痛めつける。",
            "【ほつれ】\n世界がひび割れ、ほつれが現出する。ほつれに触れたものは虚無に飲み込まれ、帰ってくることはない。",
            "【異形化】\n周囲の動物たちが歪みによって異形と化し、襲撃してくる。異形の群れ（『IZ』P237）×1D6体と戦闘になっても良い。",
            "【凍結世界】\n気温が異様に低下し、すべてのものが凍結する。また、凍結した世界の中で戦闘する全てのキャラクターは、防御判定にファンブルした場合狼狽を受ける。",
            "【天候暴走】\n大嵐、竜巻、吹雪、酷暑などの異常気象が発生する。船は木の葉のように揺れ、獣は恐怖に騒ぐ。このシーン中に行うすべての移動はその距離が半減する。",
            "【天の怒り】\n歪みによってあり得ないほどの異常気象が発生する。全てを吹き飛ばす風が吹き、雷鳴が唸る。このシーン中、あらゆるキャラクターは飛行状態になることは出来ない。",
            "【迷いの森】\n周囲の景色や地形が地図や知識にあるものと全く違っている。どこかに向かっているなら【知覚】難易度12の判定に失敗した場合、迷った結果として【MP】2D6点を失う",
            "【死の世界】\n世界は異様に美しくなる。水には一匹の魚もなく、藪には一匹の虫もいない。空に鳥は飛ばない。不気味な静寂が世界を包む。",
            "【影絵芝居】\nそこかしこの暗闇から、紡ぎ手たちの（あるいは登場するNPCの）不吉な運命を暗示する歌声が聞こえてくる。それは異形の声や虚無の軋みの音、あるいは歪みの幻影かもしれない。",
            "【色彩浸食】\n世界が漆黒と曇白に塗り分けられる。シーン内に登場するあらゆる無生物と生物は、白と黒のモノトーンの存在になる。紡ぎ手は【縫製】難易度8の判定に成功すれば、この影響を受けない。",
            "【濃霧】\nたとえそこが地底であっても、曇白の濃霧があたりを包み込む。手を伸ばしたら、その指先が見えないほどだ。濃霧内での攻撃は、敵との距離を2倍に計算する。",
            "【異形出現】\nほつれの中から、おぞましく人を襲うことしか考えぬ異形の群れが現れ、恐怖のうちに居合わせた人々を襲撃する。GMが望むなら、異形の群れ（『IZ』P237）×1D6と戦闘を行わせても良い。また、GMは状況に応じて別のエネミーを選択しても良い。",
            "【鉱脈露出】\nあり得ないほどの豊富な鉱脈が露出する。黄金、宝石、海ならば珊瑚などだ。人々は目の色を変えて鉱脈に群がる。それによってもたらされる混乱についてはGMが決定せよ。",
            "【虚無現出】\nほつれの中から虚無がしみ出す。シーンに登場しているエキストラは虫一匹にいたるまで消滅し、二度と現れない。",
            "【汚染世界】\n水は毒を含み、大気は有毒の霧に包まれる。登場している全てのキャラクターは【体力】難易度10の判定を行い、失敗すると邪毒5を受ける。エキストラがどうなるかはGMが決定するが、治療されなければ早晩死亡するだろう。",
            "【地域消滅】\n演目の舞台となっている地域そのものが消えてなくなる。影響下にあるすべてのキャラクター（伽藍を含む）は【縫製】難易度10の判定に成功すれば脱出できる。失敗した場合即座に死亡する。エキストラは無条件で死亡する。",
          ]
        ),
        "DTS" => MMTable.new(
          "歪み表(海)",
          [
            "【海域汚染】\n赤潮が発生する。あるいは海水そのものが毒に変わる。登場している全てのキャラクターは【体力】難易度10の判定を行い、失敗すると邪毒5を受ける。エキストラがどうなるかはGMが決定するが、治療されなければ早晩死亡するだろう。",
            "【色彩浸食】\n世界が漆黒と曇白に塗り分けられる。シーン内に登場するあらゆる無生物と生物は、白と黒のモノトーンの存在になる。紡ぎ手は【縫製】難易度8の判定に成功すれば、この影響を受けない。",
            "【異形の海】\n海の生物や海守りたちが異形化する。戦闘となる。GMは適切と思われるエネミーを配置すること。",
            "【海底火山】\n海底火山が噴火する。海水は熱されて周囲の生物は次々と死滅し、海守りたちも苦しむ。海からのしぶきは熱湯となる。具体的な効果はGMが決定せよ。",
            "【歪曲御標】\n歪んだ御標が下される。歪み表（『MM』P263）を振ること。",
            "【曇白の海】\n海の水が曇白になる。虚無への甘い誘いに満ちた海に触れたものは、考えることをやめ、意思なき人形のようになり、いずれ溶けて消滅してしまう。この歪みが1D6シーン（または1D6日）以内に消えない場合、すべてのキャラクターは（PCも含め）エキストラとなって二度と自我を取り戻すことはない。GMは何らかの理由で効果を受けないキャラクターを設定しても良い。",
            "【黒い海】\n海の水が漆黒に染まっていく。海の中にいると一寸先も見えない、[種別：射撃]の武器による攻撃のファンブル値を+5する。",
            "【壁面崩壊】\n海の壁面が崩壊し、ヒビが入る。ヒビを何とかすることができなければ、水圧によって1D6シーン（または1D6時間）後には崩壊し、海があふれ出すことになる。",
            "【固形化】\n海の水が固形化する。その中にいるものは氷で硬められたように身動きが取れず、ただ死を待つのみ。エキストラは完全に動けなくなる。エネミーやPCは等しく重圧＆捕縛を受ける。この効果は歪みが引き受けられるまでの間、毎シーン＆毎ラウンドの開始後に再度適用される。",
            "【氾濫】\n海の水が急激に増幅し、水槽からあふれ出す。シーンに登場している海守りのクラスを持たないキャラクターの【HP】は即座に0になる。ただし《大河の導き》の効果を受けているキャラクターと《ミズモノ》を取得しているキャラクターは3D6点の【HP】を消費することでこの効果を打ち消せる。",
            "【塩の雪】\n空から雪のように塩が降ってくる。人々は初めは喜ぶが、降り続ける雪は田畑を荒らし、人の身にも害を及ぼす。それでも塩は降り止まない。",
            "【真水化】\n海が真水になる。人間の中には喜ぶ者もいるが、海の生物たちにとっては死を意味する。",
            "【海流消失】\n海の海流が消える。海守りの力を持ってしても潮を起こすことはできない。よどんた海水は腐敗し、海の恩恵を受けて暮らす者たちは次々に病にかかる。",
            "【崩れる世界】\n海の周囲（海の内部ではなく、その外部）で爆発的にほつれが広がっていく。その規模はGMが決定するが、遠からず住人たちは死を迎えることになるだろう。",
            "【酒の海】\n海の水が酒になる。水を飲んだすべての者は酔っ払い理性を失う。その様はまるで暗黒期に滅亡した“怠惰の古都”を彷彿とさせる。",
            "【冷たき海】\n海の水が魂を凍らせるような冷たさになる。水に触れた者は暗く排他的で疑心暗鬼になり、互いを憎悪するようになる。また、全てのキャラクターは海水に触れている限り、毎シーン【MP】を2D6点失う。",
            "【大渦巻き】\n巨大な大渦が出現する。渦の中心は虚無に通じており、海守りの力を持ってしても渦を消すことはできない。海中にいる全てのキャラクターは2D6を振り、出た目に等しい【HP】を失う。ただし出目が2の場合、即座に【HP】が0となる。",
            "【海の終焉】\n海を維持している生命の力そのものが消える。水は鎖、魚はしに、波は薙ぐ。あらゆる生命は死ぬ。",
          ]
        ),
        "EDT" => DiceTable::Table.new(
          "永劫消失表",
          "2D6",
          [
            "【無慈悲な現実】\n願いも希望も叶いはしない。伽藍を倒すことができた、それが精一杯の、あなたたちに許された幸福だったのだ。意識が、虚無へと呑まれ消えていく……。\n＞ ダイスの後振りは行なえず、伽藍となる",
            "【命の消失】\n虚無はあなたの命を飲み込んでいった。身体が糸の切れた操り人形のように崩折れ、地面へと倒れ伏す。これが、あなたの人生の終わりなのだろうか………\n＞ あなたは死亡する。PCとして生き続けることを望む場合、キャラクターの成長の際にクラス：屍人（『TM』P90）を取得すること。",
            "【魂の消失】\nあなたの心に虚無が忍び寄る。まったく虚ろでからっぽな絶望。まだ、あなたは伽藍になったりなどしない。まだ……今は。\n＞ 【精神力】を-［演者レベル］D6する（下限値1）",
            "【肉体の消失】\n伽藍に捥がれたか、ほつれに呑まれたか。すべてを消失させる虚無はあなたの身体をも食らっていった。肉体の一部を失いつつも、あなたは辛うじて命を繋ぐことができたのだ。\n＞ 【耐久値】を-［演者レベル］D6する（下限値1）",
            "【思い人の消失】\n大切な誰かがいた。愛か憎悪か、あなたの人生に刻まれた無二の存在だ。だが、思いのすべては虚無に呑まれて消えてしまった。例え相手の顔を覚えていることができたとしても、胸焦がす思いはもうないのだ。\n＞ 固定化しているパートナーからひとりを選択し消失する。演目中に喪失した固定化しているパートナーがいる場合は、優先的に代償とすること。",
            "【境遇の消失】\nなぜ紡ぎ手となったのか……大切ななにかがあったはずだ。自分の人生を賭けるような、大切な、“なにか”が。けれど、もう思い出すことはできない。二度と、思い出せないだろう。\n＞ 境遇を消失する（特性も使用不可）",
            "【出自の消失】\nあなたがどこから来たのか、何者であったのか。故郷や家族の思い出が虚無の向こうに消えていく。もはや永久に、思い出すことはできないだろう。\n＞ 出自を消失する（特性も使用不可）",
            "【虚無の爪痕】\n四肢に激痛が走った。あなたの身体には虚無の爪痕がくっきりと残り、消えることなく身体を蝕み続けるだろう。\n＞ 【行動値】を-5する（下限値1）",
            "【虚無の浸食】\n鼓動が不吉なリズムを刻む。身体が、魂が虚無に侵され消え失せてしまうような恐ろしい感覚。たとえ目に見えずとも、着実にあなたは虚無へ近づいている……。\n＞ アフタープレイで基本剥離値を+3する（上限値9）。代償の支払いが可能であるかは剥離チェック時に確定すること。",
            "【異形化の発現】\nあなたの身体に禍々しい、色なき変容が現れた。ついに異形化がはじまったのだ。人々は恐れの混じった目で、君を石持て追うだろう。\n＞ あなたは異形となる。PCとして生き続けることを望む場合、キャラクター成長の際にクラス：異形（『MM』P116）を取得すること。",
            "【一念の奇跡】\n奇跡は起きた。想いが神へと届いたか、それとも紡ぎ手の一念か、その身のなにを失うこともなく、あなたはこの戦いを終えることを許されたのだ。\n＞ 代償は発生しない",
          ]
        ),
        "DTM" => MMTable.new(
          "歪み表(館・城)",
          [
            "【ほつれ】\n世界がひび割れ、ほつれが現出する。ほつれに触れたものは虚無に飲み込まれ、帰ってくることはない。",
            "【色彩浸食】\n世界が漆黒と曇白とに塗り分けられる。シーン内に存在するあらゆる無生物と生物は、白と黒のトーンの存在となる。この効果は歪みをもたらした異形の死によって解除される。",
            "【狂える色時計】\n柱時計や時計塔が狂ったように時を刻む。歪みを引き受けなかった場合、シーン内に存在するあらゆる無生物と生物は2D6年の歳月が過ぎたものとして振る舞う。生物なら老化する。",
            "【凶月】\n館の窓から曇白の月が見える。禍々しい月の光に照らされた館にいるすべての人物は、心を虚無に囚われ自ら死へと向かいはじめる。",
            "【無限図書館】\nどこまでも続く図書館。そこにある本が、知識への誘惑を囁いてくる。【意志】難易度14の判定に失敗した場合、1D6時間を浪費し、同じだけの【MP】を失う。",
            "【曇白の部屋】\n曇白の部屋に閉じ込められる。心が朽ち始め、異形へと近づいていく。この歪みが1D6シーン（または1D6時間）以内に消えない場合、すべてのキャラクターは（PCも含め）エキストラとなって二度と自我を取り戻すことはない。",
            "【悪しき鏡】\n鏡台や手鏡、鏡の部屋などから、鏡の中の自分がにやにやとこっちを見ている。すべての紡ぎ手の行なう判定のファンブル値を+3する。",
            "【歪みの音色】\n館内に人を不安にさせる音楽が響きはじめる。心はかき乱され、自分以外の誰もが化け物の姿に見えはじめる。【縫製】難易度8の判定に失敗したキャラクターは即座に【MP】が0になる。",
            "【暗闇の回廊】\n光をも塗りつぶす漆黒の闇が満ち、蝋燭の灯がすべて消える。何らかの手段で魔法的な光をPCたちが有していない限り、射撃攻撃の達成値は-5される。何らかの暗視能力や強力な嗅覚などを持つ、とGMが判断したキャラクターはこの効果を受けない。",
            "【動く植物】\n屋敷の植物、鳥や薔薇などが動き出し、襲いかかってくる。【反射】難易度12の判定に失敗すると、〈斬〉5D6のダメージを受ける。",
            "【黒い影】\n歪みによって、館に（あるいは館の建っている場所に）住んでいた過去の人物たちが影となって蘇り、館内を徘徊する。【反射】難易度10の判定に失敗したPCは発見され、【MP】4D6点となる。",
            "【凶暴な獣】\n館に飼われている猛獣や、屋敷に住み着くネズミや鳥などが異形化し襲いかかってくる。GMは適切なエネミーを登場させ、戦闘を行なってもよい。",
            "【牙持つ部屋】\n部屋が歪み、入ってきたものを食らおうと牙を剥く。室内にいるすべてのキャラクターは2D6を振り、出た目に等しい【HP】を失う。ただし出目が2の場合、即座に【HP】が0となる。",
            "【灼熱の暖炉】\n暖炉から炎が噴き出し襲いかかる。登場しているキャラクターは【反射】難易度12の判定を行ない、失敗すると【HP】4D6点を失う。",
            "【無限回廊】\n果てしなく続く通廊に迷い込む。どこまで行っても同じ部屋だ。1D6時間【あるいはGMが定めた時間】を浪費し、同じだけの【HP】を失う。",
            "【奇妙な人形】\n登場キャラクターと同じ顔の人形かからくりが現われ話しかけてくる。幻影か、そのように作られているのかは歪みを引き受けるまでわからない。登場しているPCはシーン終了時に【MP】を2D6点失う。",
            "【動く家具】\n椅子や戸棚、シャンデリアなどの家具、あるいはからくりが歪みの影響で動き襲いかかってくる。GMは任意のエネミーを登場させ、戦闘を行なってもよい。",
            "【炎上】\n館が炎上をはじめる。ここに留まっていれば、問答無用で死ぬことになるだろう。",
          ]
        ),
      }.freeze

      register_prefix(['\d+D6.*'] + TABLES.keys)
    end
  end
end
