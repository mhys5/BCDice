# frozen_string_literal: true

module BCDice
  module GameSystem
    class FutariSousa < Base
      # ゲームシステムの識別子
      ID = 'FutariSousa'

      # ゲームシステム名
      NAME = 'フタリソウサ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ふたりそうさ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・判定用コマンド
        探偵用：【DT】…10面ダイスを2つ振って判定します。『有利』なら【3DT】、『不利』なら【1DT】を使います。
        助手用：【AS】…6面ダイスを2つ振って判定します。『有利』なら【3AS】、『不利』なら【1AS】を使います。
        ・各種表
        【調査時】
        異常な癖決定表 SHRD
        　口から出る表 SHFM／強引な捜査表　　　 SHBT／すっとぼけ表　 SHPI
        　事件に夢中表 SHEG／パートナーと……表 SHWP／何かしている表 SHDS
        　奇想天外表　 SHFT／急なひらめき表　　 SHIN／喜怒哀楽表　　 SHEM
        イベント表
        　現場にて　 EVS／なぜ？　 EVW／協力者と共に EVN
        　向こうから EVC／VS容疑者 EVV
        調査の障害表 OBT　　変調表 ACT　　目撃者表 EWT　　迷宮入り表 WMT
        【設定時】
        背景表
        　探偵　運命の血統 BGDD／天性の才能 BGDG／マニア　　　　 BGDM
        　助手　正義の人　 BGAJ／情熱の人　 BGAP／巻き込まれの人 BGAI
        身長表 HT　　たまり場表 BT　　関係表 GRT　　思い出の品決定表 MIT
        職業表A・B　　JBT66・JBT10　　ファッション特徴表A・B　　　　FST66・FST10
        感情表A／B　　FLT66・FLT10　　好きなもの／嫌いなもの表A・B　LDT66・LDT10
        呼び名表A・B　NCT66・NCT10
      MESSAGETEXT

      def initialize
        super

        @enabled_d66 = true
        @d66_sort_type = D66SortType::ASC

        @success_threshold = 4 # 成功の目標値（固定）
        @special_dice = 6 # スペシャルとなる出目（ダイスの種別によらず固定）
      end

      register_prefix(
        ['(\d+)?DT', '(\d+)?AS', 'SHRD', 'SHFM', 'SHBT', 'SHPI', 'SHEG', 'SHWP', 'SHDS', 'SHFT', 'SHIN', 'SHEM', 'EVS', 'EVW', 'EVN', 'EVC', 'EVV', 'OBT', 'ACT', 'EWT', 'WMT', 'BGDD', 'BGDG', 'BGDM', 'BGAJ', 'BGAP', 'BGAI', 'HT', 'BT', 'GRT', 'MIT', 'JBT66', 'JBT10', 'FST66', 'FST10', 'FLT66', 'FLT10', 'LDT66', 'LDT10', 'NCT66', 'NCT10',]
      )

      def rollDiceCommand(command)
        output = '1'
        type = ""
        diceText = ""

        case command
        when /^(\d+)?DT$/i
          type = command
          count = (Regexp.last_match(1) || 2).to_i
          output, diceText = get_dt(count)
        when /^(\d+)?AS$/i
          type = command
          count = (Regexp.last_match(1) || 2).to_i
          output, diceText = get_as(count)
        when 'SHRD'
          type = '異常な癖決定表'
          output, diceText = get_strange_habit_random
        when 'SHFM'
          type = '異常な癖・口から出る表'
          output, diceText = get_strange_habit_from_mouth
        when 'SHBT'
          type = '異常な癖・強引な捜査表'
          output, diceText = get_strange_habit_bull_through
        when 'SHPI'
          type = '異常な癖・すっとぼけ表'
          output, diceText = get_strange_habit_play_innocent
        when 'SHEG'
          type = '異常な癖・事件に夢中表'
          output, diceText = get_strange_habit_engrossed
        when 'SHWP'
          type = '異常な癖・パートナーと……表'
          output, diceText = get_strange_habit_with_partner
        when 'SHDS'
          type = '異常な癖・何かしている表'
          output, diceText = get_strange_habit_do_something
        when 'SHFT'
          type = '異常な癖・奇想天外表'
          output, diceText = get_strange_habit_fantastic
        when 'SHIN'
          type = '異常な癖・急なひらめき表'
          output, diceText = get_strange_habit_inspiration
        when 'SHEM'
          type = '異常な癖・喜怒哀楽表'
          output, diceText = get_strange_habit_emotion
        when 'EVS'
          type = '現場にて／イベント表'
          output, diceText = get_event_scene
        when 'EVW'
          type = 'なぜ？／イベント表'
          output, diceText = get_event_why
        when 'EVN'
          type = '協力者と共に／イベント表'
          output, diceText = get_event_npc
        when 'EVC'
          type = '向こうから／イベント表'
          output, diceText = get_event_coming
        when 'EVV'
          type = 'VS容疑者／イベント表'
          output, diceText = get_event_vs
        when 'OBT'
          type = '調査の障害表'
          output, diceText = get_obstruction_table
        when 'ACT'
          type = '変調表'
          output, diceText = get_abnormal_condition
        when 'EWT'
          type = '目撃者表'
          output, diceText = get_eyewitness_table
        when 'WMT'
          type = '迷宮入り表'
          output, diceText = get_wrapped_in_mystery_table
        when 'BGDD'
          type = '探偵・運命の血統 背景表'
          output, diceText = get_background_detective_destiny
        when 'BGDG'
          type = '探偵・天性の才能 背景表'
          output, diceText = get_background_detective_genius
        when 'BGDM'
          type = '探偵・マニア 背景表'
          output, diceText = get_background_detective_mania
        when 'BGAJ'
          type = '助手・正義の人 背景表'
          output, diceText = get_background_assistant_justice
        when 'BGAP'
          type = '助手・情熱の人 背景表'
          output, diceText = get_background_assistant_passion
        when 'BGAI'
          type = '助手・巻き込まれの人 背景表'
          output, diceText = get_background_assistant_involved
        when 'HT'
          type = '身長表'
          output, diceText = get_height_table
        when 'BT'
          type = 'たまり場表'
          output, diceText = get_base_table
        when 'GRT'
          type = '関係表'
          output, diceText = get_guest_relation_table
        when 'MIT'
          type = '思い出の品決定表'
          output, diceText = get_memorial_item_table
        when 'JBT66'
          type = '職業表A'
          output, diceText = get_job_table_66
        when 'JBT10'
          type = '職業表B'
          output, diceText = get_job_table_10
        when 'FST66'
          type = 'ファッション特徴表A'
          output, diceText = get_fashion_table_66
        when 'FST10'
          type = 'ファッション特徴表B'
          output, diceText = get_fashion_table_10
        when 'FLT66'
          type = '感情表A'
          output, diceText = get_feeling_table_66
        when 'FLT10'
          type = '感情表B'
          output, diceText = get_feeling_table_10
        when 'LDT66'
          type = '好きなもの／嫌いなもの表A'
          output, diceText = get_like_dislike_table_66
        when 'LDT10'
          type = '好きなもの／嫌いなもの表B'
          output, diceText = get_like_dislike_table_10
        when 'NCT66'
          type = '呼び名表A'
          output, diceText = get_name_to_call_table_66
        when 'NCT10'
          type = '呼び名表B'
          output, diceText = get_name_to_call_table_10
        end

        return "#{type}(#{diceText}) ＞ #{output}"
      end

      # DT
      def get_dt(count)
        diceList = []
        count.times do
          dice, =  roll(1, 10)
          diceList << dice
        end

        output = get_dt_result(diceList)
        diceText = diceList.join(",")

        return output, diceText
      end

      def get_dt_result(diceList)
        max = diceList.max

        return "ファンブル（変調を受け、助手の心労が1点上昇）" if max <= 1
        return "スペシャル（助手の余裕を1点獲得）" if diceList.include?(@special_dice)
        return "成功" if max >= @success_threshold

        return "失敗"
      end

      # AS
      def get_as(count)
        diceList = []
        count.times do
          dice, =  roll(1, 6)
          diceList << dice
        end

        output = get_as_result(diceList)
        diceText = diceList.join(",")

        return output, diceText
      end

      def get_as_result(diceList)
        max = diceList.max

        return "ファンブル（変調を受け、心労が1点上昇）" if max <= 1
        return "スペシャル（余裕2点と、探偵から助手への感情を獲得）" if diceList.include?(@special_dice)
        return "成功（余裕1点と、探偵から助手への感情を獲得）" if max >= @success_threshold

        return "失敗"
      end

      def getTableResult(table, dice)
        number, text, command = table.assoc(dice)

        if command.respond_to?(:call)
          text += command.call(self)
        end

        return number, text
      end

      def getAddRollProc(command)
        # 引数なしのlambda
        # Ruby 1.8と1.9以降で引数の個数の解釈が異なるため || が必要
        lambda { getAddRoll(command) }
      end

      def getAddRoll(command)
        return command if command =~ /^\s/

        text = rollDiceCommand(command)
        return " ＞ #{command} is NOT found." if text.nil?

        return " ＞ \n #{command} ＞ #{text}"
      end

      # 異常な癖決定表
      def get_strange_habit_random
        table = [
          [1, '「異常な癖・口から出る表」の表を使用する。'],
          [2, '「異常な癖・強引な捜査表」の表を使用する。'],
          [3, '「異常な癖・すっとぼけ表」の表を使用する。'],
          [4, '「異常な癖・事件に夢中表」の表を使用する。'],
          [5, '「異常な癖・パートナーと……表」の表を使用する。'],
          [6, '「異常な癖・何かしている表」の表を使用する。'],
          [7, '「異常な癖・急なひらめき表」の表を使用する。'],
          [8, '「異常な癖・喜怒哀楽表」の表を使用する。'],
          [9, '「異常な癖・奇想天外表」の表を使用する。'],
          [10, '好きな「異常な癖」の表を使用する。'],
        ]
        diceText = @randomizer.roll_once(10)
        output = get_table_by_number(diceText, table)
        return output, diceText
      end

      def get_strange_habit_from_mouth
        table = [
          [1, '猛烈に感謝の言葉を述べる'],
          [2, '皮肉ばかり言ってしまう'],
          [3, '相手の言葉を肯定してから否定する'],
          [4, 'ニヤニヤ笑いながら謝る'],
          [5, '相手の言葉を聞かずに自分だけ喋る'],
          [6, '「こうは考えられないでしょうか」'],
          [7, '「それとも、何か隠していることでも？」'],
          [8, '「妙ですね」'],
          [9, '「だいたいわかりました」'],
          [10, '「黙っていろ」'],
        ]
        diceText = @randomizer.roll_once(10)
        output = get_table_by_number(diceText, table)
        return output, diceText
      end

      def get_strange_habit_bull_through
        table = [
          [1, '勝手に捜査対象の鞄や引き出しを開ける'],
          [2, '警察の捜査に割り込む'],
          [3, '捜査のためにハッキングや不法侵入を行う'],
          [4, '許可されていないところに立ち入る'],
          [5, '警察の捜査を盗み見や盗み聞きする'],
          [6, '証拠品を許可なく解体する'],
          [7, '捜査対象を騙して情報を聞き出す'],
          [8, '勝手に関係者の持ち物を触る'],
          [9, '証拠品を勝手に持ち歩いている'],
          [10, '勝手に鑑識を始める'],
        ]
        diceText = @randomizer.roll_once(10)
        output = get_table_by_number(diceText, table)
        return output, diceText
      end

      def get_strange_habit_play_innocent
        table = [
          [1, '自分の身分を偽って関係者に話を聞く'],
          [2, '情報を隠しながら話を聞く'],
          [3, 'パートナーと演技をして情報を聞き出そうとする'],
          [4, '通行人のふりをして、関係者の話を盗み聞き'],
          [5, '偶然を装って証拠品を手に入れてしまう'],
          [6, 'わざとらしくすっとぼける'],
          [7, '関係者を怒らせる演技をして、情報を引き出す'],
          [8, 'やんわりと関係者を脅す'],
          [9, '落し物をしたと主張して現場や証拠品を漁る'],
          [10, '関係者に誘導尋問を仕掛ける'],
        ]
        diceText = @randomizer.roll_once(10)
        output = get_table_by_number(diceText, table)
        return output, diceText
      end

      def get_strange_habit_engrossed
        table = [
          [1, 'パートナーの体を使って事件を再現しようとする'],
          [2, '謎を解くことが楽しくて笑ってしまう'],
          [3, '寝食を忘れて捜査をしていたので急に倒れる'],
          [4, '考え事をしていて、誰の声も聞こえない'],
          [5, '事件の相関図を手近な壁や床に描き始める'],
          [6, '事件に関係する言葉を次々に発して止まらない'],
          [7, '事件解決以外のことをまったく考えていない'],
          [8, '事件の流れをぶつぶつと喋り始める'],
          [9, '事件現場に踏み込んで調べ物をする'],
          [10, '食事中でも、かまわずに事件の話をする'],
        ]
        diceText = @randomizer.roll_once(10)
        output = get_table_by_number(diceText, table)
        return output, diceText
      end

      def get_strange_habit_with_partner
        table = [
          [1, 'パートナーの信頼に甘える'],
          [2, 'パートナーを置いて先に行ってしまう'],
          [3, 'パートナーに事件についてどう思っているか質問する'],
          [4, 'パートナーに自慢する'],
          [5, 'パートナーに事件に関するクイズを出題する'],
          [6, 'パートナーと些細なことで喧嘩をする'],
          [7, 'パートナーに教師のようにふるまう'],
          [8, 'パートナーがついてくる前提で勝手に動く'],
          [9, 'パートナーに対して懇切丁寧に事件を説明する'],
          [10, 'パートナーの耳元でいきなり喋り始める'],
        ]
        diceText = @randomizer.roll_once(10)
        output = get_table_by_number(diceText, table)
        return output, diceText
      end

      def get_strange_habit_do_something
        table = [
          [1, '大量の本を読んでいる'],
          [2, '好きな音楽を大音量で流している'],
          [3, '何かの数式を解いている'],
          [4, '大量の好物をずっと食べている'],
          [5, 'ずっとパソコンやスマートフォンなどの画面と向かい合って調べている'],
          [6, '小さな謎を解いている'],
          [7, 'チェスや将棋などを指している'],
          [8, '喫茶店の席に座って何かを待っている'],
          [9, 'ずっと眠っていたが急に起きる'],
          [10, 'しばらく何もしていない'],
        ]
        diceText = @randomizer.roll_once(10)
        output = get_table_by_number(diceText, table)
        return output, diceText
      end

      def get_strange_habit_fantastic
        table = [
          [1, 'やめろと言われていることをする'],
          [2, 'しばらく姿を消していたが戻って来た'],
          [3, '予想もつかないところ（地中や空中など）から登場する'],
          [4, '何かを思いついて突然走り出す'],
          [5, 'ふがいない自分を責める'],
          [6, '知らないうちに事件の謎を一つ解いていた'],
          [7, '事件について分かった様子だが誰にも教えない'],
          [8, '置き手紙やメールで報告をするも姿が見えない'],
          [9, '時計を見て、急に動き出した'],
          [10, '事件とは関係なさそうな新聞の記事を読んでいる'],
        ]
        diceText = @randomizer.roll_once(10)
        output = get_table_by_number(diceText, table)
        return output, diceText
      end

      def get_strange_habit_inspiration
        table = [
          [1, '食事をとっていたら急に謎が解ける'],
          [2, '助手との何気ない会話から急に謎が解ける'],
          [3, '聞こえてきた会話から急に謎が解ける'],
          [4, '風呂に入っていたら急に謎が解ける'],
          [5, '夢の中で急に謎が解ける'],
          [6, '風が吹いて飛んできた物で謎が解ける'],
          [7, '本を読んでいたら事件のヒントが見つかる'],
          [8, '現場を再び訪れてひらめく'],
          [9, '資料を確認している最中にひらめく'],
          [10, '関係者と会話をしている最中にひらめく'],
        ]
        diceText = @randomizer.roll_once(10)
        output = get_table_by_number(diceText, table)
        return output, diceText
      end

      def get_strange_habit_emotion
        table = [
          [1, '急に泣く'],
          [2, '急に怒る'],
          [3, '急に笑いだす'],
          [4, '急にハイテンションになる'],
          [5, '急に喜ぶ'],
          [6, '急に叫ぶ'],
          [7, '急にニヤニヤし始める'],
          [8, '急にこの事件の悲しさを語る'],
          [9, '淡々と物事を進める'],
          [10, 'ロボットのように決められたことだけをやる'],
        ]
        diceText = @randomizer.roll_once(10)
        output = get_table_by_number(diceText, table)
        return output, diceText
      end

      # イベント表
      def get_event_scene
        table = [
          "気になるもの（P.165）\n　事件の起きた現場は、まだ残されている。\n　ここで起きた“何か”は、霧の向こうに隠されていた。\n　その霧に手を突っ込む者たちがいる。",
          "煙たがられる（P.166）\n　刑事が一人、現場を熱心に見て回っている。\n　この事件の担当を任された刑部正義という男だ。\n　彼は、PCたちの顔を見るなり、顔をしかめた。歓迎されていない。",
          "聞き込み（P.167）\n　PCたちは、現場付近を通りがかったり、事件を目撃したりした人物がいないか探し回っていた。\n　しかし、どこで何を聞いても、それらしい手がかりはない。\n　そろそろ、足に疲労が蓄積してきた。",
          "頑なな関係者（P.168）\n　事件現場に、とある人物が現れた。\n　探偵たちは、神妙な顔で現場を見つめていたその人物が気になって、声をかける。\n　その人物は、自らを被害者の関係者と名乗った……。",
          "現場徹底調査！（P.169）\n　事件現場に残された証拠は、あらかた見つけた。\n　……はたして、本当にそうだろうか？\n　あらゆる角度から調査と検証をし、現場に残されたものはないか、調べることになった。",
          "逃げた人物（P.170）\n　脱兎のごとく、誰かが現場から逃げている。\n　その人物の走り方、焦り方は普通ではなかった。\n　これは、何かを知っている。あるいは、何かを持ち去った可能性がある。\n　PCたちは、追いかけ始めた。",
        ]
        return get_table_by_1d6(table)
      end

      def get_event_why
        table = [
          "移動ルート（P.171）\n　この道を通ったとき、あの人は何を思っただろうか？\n　この道を通った時、あの人は何をしなければならなかったのか？\n　事件関係者の足取りには、事件に繋がる何かが残されている。\n　そう信じて、道を歩く。",
          "自分なら……（P.172）\n　探偵と助手が事件について語り合っていた。\n　話のお題は、「この状況で、自分が犯人ならどうするか」。\n　その仮定は、ヒントを与えてくれるかもしれない。",
          "謎のメッセージ（P.173）\n　それは、謎の言葉だった。\n　ただの文字列かもしれないし、意味不明な言葉かもしれない。\n　事件に関わる場所にあったからといって、事件に関わっているとは限らない。\n　だけど、これは事件に関わっている。そう直感が告げている。",
          "事件のおさらい（P.174）\n　ホワイトボード、黒板、ノート。\n　なんでもいいから、書くものが必要だ。\n　今から、事件についてまとめるのだから。",
          "怪しい人物は？（P.175）\n　探偵たちは、一人の人物を追っている。\n　その人物は、事件に繋がる何かを持っている。そういう確信があった。\n　さて、実際のところ、彼は何者なのだろうか？",
          "被害者の視点（P.176）\n　被害者の身に何が起こったのか。\n　被害者は何を見たのか。\n　そのヒントは、被害者自身が知っているはずだ。",
        ]
        return get_table_by_1d6(table)
      end

      def get_event_npc
        table = [
          "事件の映像（P.177）\n　PCたちは目を細めて、映像を眺めている。\n　それは、偶然にも現場で撮られたものだった。\n　果たして、真実はこの映像の中に、映っているのだろうか？",
          "変わった目撃者（P.178）\n　探偵たちは捜査の結果、事件に関する何かを見たという目撃者を見つける。\n　しかし、その人物は目撃証言を渋った。どうしてだろうか？",
          "専門家（P.179）\n　調査中、どうしても専門的な知識が必要な場面が出てくる。\n　今がその時であり、探偵たちはどうしようかと悩んでいた。",
          "情報屋（P.180）\n　メールソフトに連絡が入った。\n　連絡を入れてきたのは、界隈では有名な情報屋だった。\n　その情報屋にかかれば、手に入らない情報はないという。\n　さて、どうしようか。",
          "関係者と一緒に（P.181）\n　事件関係者の一人が、突然協力を持ちかけてきた。\n　どうやら、その人もこの事件には思うところがあるらしい。",
          "素人推理（P.182）\n　事件関係者の前で、ゲストNPCが推理を披露している。\n　だけど、その推理は穴だらけで……。",
        ]
        return get_table_by_1d6(table)
      end

      def get_event_coming
        table = [
          "不審な電話（P.183）\n　突然、電話が鳴り響いた。\n　その電話は調査を進展させることになるが……。\n　同時に、新たな謎を残した。",
          "今は余暇を（P.184）\n　果報は寝て待て。\n　待てば海路の日和あり。\n　ということで、ひとまずたまり場にいる。\n　果たして、事態は好転するのだろうか？",
          "道端でばったり（P.185）\n　犬も歩けば棒に当たる。\n　この言葉には、幸運にぶつかるという意味も、災難に当たるという意味も込められている。\n　では、探偵と助手が歩いたら、何に当たるのだろうか？",
          "ひらめきの瞬間（P.186）\n　ふとしたきっかけで、探偵はひらめくことがある。\n　今回は、一体何がきっかけだったのだろうか？",
          "知り合いから（P.187）\n　事件捜査の手がかりを持ってきたのは、知り合いだった。\n　持つべきものは友。\n　と言いたいところだが……。",
          "探偵たちのピンチ（P.188）\n　捜査は突然ストップした。\n　その原因はわかっている。\n　原因を取り除かなければ、事件の調査どころではない。",
        ]
        return get_table_by_1d6(table)
      end

      def get_event_vs
        table = [
          "容疑者の嘘（P.189）\n　人は、何か後ろめたいことがあったとき、嘘をつく。\n　この容疑者は嘘をついている。\n　なら、何を隠しているのだろうか？",
          "ゆさぶり（P.190）\n　その容疑者は、何かを隠していた。\n　目立った嘘をついているわけではない。\n　だけれども、何かを隠している。探偵には、そう見えた。",
          "外見からの推理（P.191）\n　少しだけ、話をした。\n　少しだけ、その姿を見た。\n　少しだけ、その人を知った。\n　それだけで、探偵という生き物は十を知ってしまう。そういうものなのだ。",
          "直接尋ねる（P.192）\n　ここにきて、探偵と助手は大胆な手に出た。\n　容疑者に対して、事件の具体的なところまで突っ込んだ質問をしたのだ。\n　それに対して、容疑者は……。",
          "脅される（P.193）\n　どうやら、自分たちは脅されているようだ。",
          "鬼の居ぬ間に（P.194）\n　その容疑者の元を訪ねたとき、偶然にも席をはずしていた。\n　これはチャンス。\n　そう思ってしまうのが、探偵の悲しい性だ。",
        ]
        return get_table_by_1d6(table)
      end

      # 調査の障害表
      def get_obstruction_table
        table = [
          [11, '探偵と助手が警察にマークされる'],
          [12, '探偵の気まぐれ'],
          [13, '探偵のやる気'],
          [14, '探偵の奇行に耐えられなくなる'],
          [15, '探偵が奇異の眼に晒される'],
          [16, '探偵が疲れる'],
          [22, '探偵と助手が不審者に間違われる'],
          [23, '助手がパートナーに信頼されていないと思う'],
          [24, '探偵に助手がついていけない'],
          [25, '助手の苦労がいつも以上に大きい'],
          [26, '助手の捜査だけがうまくいかない'],
          [33, '捜査のための資金がない'],
          [34, '世間の眼が厳しい'],
          [35, '警察から疎ましく思われる'],
          [36, '関係者に協力してもらえない'],
          [44, '捜査してはいけないと圧力がかかる'],
          [45, '犯人による妨害'],
          [46, '犯人による裏工作'],
          [55, '植木鉢や鉄骨など、不自然に危険な物が飛んでくる'],
          [56, '何者かが探偵と助手に襲い掛かる'],
          [66, '偶然が積み重なってうまくいかない'],
        ]

        return get_table_by_d66_swap(table)
      end

      # 変調表
      def get_abnormal_condition
        table = [
          'すれ違い',
          '探偵の暴走',
          '喧嘩',
          '迷子',
          '悪い噂',
          '注目の的',
        ]
        return get_table_by_1d6(table)
      end

      # 目撃者表
      def get_eyewitness_table
        table = [
          "遊び相手が欲しい若者。判定技能：≪流行≫",
          "物覚えが悪い人。判定技能：なし",
          "忙しい人。判定技能：≪ビジネス≫",
          "犯人の知り合い。判定技能：≪説得≫",
          "探偵（警察）嫌い。判定技能：≪嘘≫",
          "反社会主義者。判定技能：≪突破≫",
        ]
        return get_table_by_1d6(table)
      end

      # 迷宮入り表
      def get_wrapped_in_mystery_table
        table = [
          [1, '真犯人とは別の人間が犯人にされてしまい、実刑を食らってしまった。その証拠はないが、そう直感できる。'],
          [2, '解決されないまま時が過ぎ、やがて事件のことは忘れられた。探偵と助手、それから事件関係者だけが覚えている。'],
          [3, '被害者遺族や関係者は悲しみに暮れている。探偵と助手は、それを黙ってみていることしかできない。あのとき、犯人を捕まえていれば……。'],
          [4, '警察によって、犯人が検挙された。だけど、その人が本当に犯人かどうかはわからない。探偵も、何とも言えないようだ。'],
          [5, '証拠がなくなってしまっている。あれさえあれば、事件の調査を再開できるのに……。犯人の仕業かどうかすら、わからない。'],
          [6, '関係者がいなくなってしまた。その後、消息も不明だ。いったい何を思って消えたのだろうか？　ともかく、調査はできなくなった。'],
          [7, '関係者から嫌われてしまい、近寄ることすらできなくなった。探偵と助手は揃って出禁になってしまったようだ。これでは、調査ができない。'],
          [8, '助手はときどき、被害者の関係者と会っている。彼らの話を聞いて、彼らの感情を受け止めているようだ。'],
          [9, '探偵と助手は機会を見つけては、事件を再調査している。しかし、確かな証拠は見つからないまま時が過ぎていく。'],
          [10, '探偵は直感によって、真犯人を突き止めた。だが、真犯人を捕まえるための証拠がない。犯人を告発することができず、歯噛みをした。'],
        ]

        diceText = @randomizer.roll_once(10)
        output = get_table_by_number(diceText, table)
        return output, diceText
      end

      # 背景表
      def get_background_detective_destiny
        table = [
          [1, '『名探偵の先祖（真）』自分の先祖に著名な探偵がいる。その名を出せば、誰もが知るような大人物だ。自分はその血を濃く引いているようで、探偵としての才能を存分に発揮している。'],
          [2, '『名探偵の先祖（想）』自分の先祖は著名な探偵だ。しかし、その活躍は「フィクション」として語られている。その人物は実在しないと言われているが……それは真実ではない。自分がその血を引いているのだから。'],
          [3, '『親が世界的探偵』自分の親は、世界的に名の知れた名探偵だ。数々の難事件も解決している。自分にもその血が流れていて、事件に対する鋭い洞察力を受け継ぐことになった。'],
          [4, '『街の名探偵』自分の親は、街ではよく名の知れた名探偵だ。街の人々から愛され、頼りにされていた。自分もその血を引いているのか、探偵として活動する力が備わっている。'],
          [5, '『推理作家』自分を育てた人物は、著名な推理作家であった。その思考能力は自分にも継がれており、トリックを暴く力は探偵並みにあると言っていいだろう。'],
          [6, '『育ての親』自分を育ててくれた人物は、事件を解決に導いたことのある人物である。その人物の教えを受けて、自分は探偵の才を開花させた。'],
          [7, '『堕ちた名探偵』かつて、自分の親はあらゆる事件を解決し、名探偵として有名だった。しかし、今では優れた思考能力を悪用し、人々を駒のように扱っている。能力を引き継いだ自分もいつかはそうなるのだろうか？'],
          [8, '『大悪人の血』世間を騒がせた大悪党や大怪盗。その血が自分にも流れている。故に悪人の思考をトレースすることができ、結果として名探偵のようにふるまえる。'],
          [9, '『隠された血筋』どういう訳か、自分のルーツは抹消されている。自分が何者なのかすら、わからない。ただ、自分には事件を解決できる力があって、それがルーツに関係していると直感できる。'],
          [10, '『クローン』自分は有名な名探偵のDNAから生まれた存在だ。そのためか、名探偵の力は生まれながらに備わっていた。'],
        ]
        diceText = @randomizer.roll_once(10)
        output = get_table_by_number(diceText, table)

        return output, diceText
      end

      def get_background_detective_genius
        table = [
          [1, '『超エリート』自分はエリートとして活躍すべく、あらゆる分野の訓練を行った。そして、望まれるままに優秀な人間となった。'],
          [2, '『瞬間記憶能力』見たものはすべて頭の中にインプットされる。そして、決して忘れない。自分はそういう能力を備えている。'],
          [3, '『知識の泉』頭の中にある引き出しの中には、あらゆる知識が収められている。つまり、知らないことはないということだ。'],
          [4, '『スパルタ教育』厳しい教育を受け、その結果知識を得ることができた。その代わり、少し変わった思考方法になってしまったが……。大したことではないだろう。'],
          [5, '『既に名探偵』既に幾多の事件を解決している天才である。数々の難事件も、自分の手腕で解決してきた。その傍らには、パートナーの姿もあった。'],
          [6, '『憧れの背中』自分には憧れている相手がいた。その存在に追いつくために、努力をし、今の能力を手に入れた。その人物は、今は……。'],
          [7, '『ライバル』自分と競い合っていたライバルがいる。能力としては、ほぼ互角だった。競い合いの中で、自分の能力は磨かれていったのである。'],
          [8, '『かつての名探偵』かつては、あらゆる事件を解決に導いた天才であった。しかし、今は事件解決に消極的である。事件を遠ざけたいと思う何かがあったのだ。'],
          [9, '『孤立した名探偵』自分は天才的な能力を持って数多の事件を解決した名探偵である。それ故に疎まれ、恐れられ、世間や組織の中で孤立をしてしまっている。'],
          [10, '『人工名探偵』自分は何者かによって軟禁されて探偵知識を詰め込まれた、「人口名探偵」だ。名探偵になるべくして育てられた自分は、その能力を期待通りに発揮することができる。'],
        ]
        diceText = @randomizer.roll_once(10)
        output = get_table_by_number(diceText, table)

        return output, diceText
      end

      def get_background_detective_mania
        table = [
          [1, '『サスペンスマニア』自分はサスペンスもののフィクションや、実在する事件に対して非常に強い関心を寄せている。ため込んだトリックの知識を活かすことができる機会を窺っている。'],
          [2, '『死体マニア』自分は死体に対して強い関心を寄せている。死体の状態や詳細を知ることによって、強い興奮を覚えるという性質なのだ。困ったものだ。'],
          [3, '『科学マニア』科学によって解明できないことはない。自分はそう考えているし、そのために能力を磨いてきた。人の起こす事件であれ、科学はすべてを見通すことができるだろう。'],
          [4, '『いわゆるオタク』ゲームや漫画などで得た知識というのは、案外バカにならないものだ。自分はゲームを通じて様々な知識をため込んでおり、それを応用することであらゆる事件を解決する。'],
          [5, '『人間マニア』自分は人間が好きだ。それ故に、観察もしている。行動に当人もわからない理由があることも知っている。事件も、どうしてそんなことを起こしたのかに興味がある。'],
          [6, '『書物マニア』書物には、あらゆることが書かれている。少なくとも自分はそう考えているし、その証拠に本の知識を応用することで、難事件も解決できる。紙上の名探偵のように。'],
          [7, '『オカルトマニア』オカルトや超常現象を信じている。それ故に、インチキを見破る術も知っているし、許せないと感じている。それが、どういうわけか難事件の解決にも繋がる。不思議だ。'],
          [8, '『探偵マニア』古今東西、様々な探偵がいる。それについて調べていくうちに、自分もまた探偵としての能力が備わった。'],
          [9, '『暴走する知識欲』自分は一つのことのマニアであるが、それから派生した物の知識もよく知っている。自分の知識欲は、それからさらに派生したものまで及ぶ。'],
          [10, '『正義のマニア』自分が信奉している何か（書物や科学など）が、事件に関わっているとなると、居ても立っても居られない。マニアとして、その謎を解明しなければならない。'],
        ]
        diceText = @randomizer.roll_once(10)
        output = get_table_by_number(diceText, table)

        return output, diceText
      end

      def get_background_assistant_justice
        table = [
          '『お人よし』自分は他者からよくお人よしと言われている。そのため、人に頼まれて事件に絡むことがよくあった。だから、人の悩みを解決できる能力があるパートナーと一緒にいる。',
          '『許せない』自分は事件の被害者に対して入れ込むタイプだ。被害者の気持ちを考えると、やりきれない思いと共に、犯人を許せないという気持ちが湧いてくる。だから、犯人を追うためにパートナーが必要だ。',
          '『納得したい』自分が事件に対して首を突っ込むのは、自分の中に納得が欲しいからだ。事件を通じて何らかの解答を見つけるために、正義を行っている。パートナーは、そのために必要な人間だ。',
          '『利用している』どんな手段を使ってでも、事件を解決するのが正しいと自分は考えている。そのための道具として、パートナーを使っているだけだ。',
          '『頼れる協力者』パートナーのことを頼れる協力者であると感じている。パートナーは自分が困ったとき、迷ったときに、答えを示してくれる人間だと思っている。相手がどう思っていようが、それは変わらない。',
          '『正義の同志』パートナーも、一緒に正義のために事件解決をしてくれている。自分はそう感じている。思い込んでいるだけかもしれないが、その思い込みは止められない。ひょっとしたら自分の方がパートナーを振り回しているのかも。',
        ]
        return get_table_by_1d6(table)
      end

      def get_background_assistant_passion
        table = [
          '『能力にほれ込んだ』自分はパートナーの事件に関する能力にほれ込んだ。その鋭い洞察力や、推理力、知識の深さ。すべてが自分を魅了している。',
          '『人柄にほれ込んだ』自分がパートナーと組んでいるのは、人格の面が大きい。一見わかりづらいところもあるが、隠された本質に自分はほれ込んでいる。',
          '『一目惚れ』はじめて会ったときから、パートナーのことが気になっていた。その能力もさることながら、直感めいたものを感じたのだ。だから一緒にいる。',
          '『ウマが合った』自分とパートナーは話が合う。二人なら盛り上がれるし、二人ならなんでもできる。そう思っている。……自分がそう思っているだけかもしれないが。',
          '『対立』パートナーと自分は対立している。それでも一緒にいるのは、パートナーのことを理解するためだ。……いつか、パートナーを倒す手段を見つけるために。',
          '『放っておけない』パートナーのことを放っておくと何をしでかすかわからない。だから、自分が見張っていないといけない。そう感じた。',
        ]
        return get_table_by_1d6(table)
      end

      def get_background_assistant_involved
        table = [
          '『一方的に気に入られた』パートナーから、一方的に気に入られている。どうしてそうなったのかはわからないが、そういうものらしい。一緒にいるのは、不本意なのだけど……。',
          '『リアクション要員』パートナーによると、自分はリアクションを期待されているらしい。事件を解決したときや、何らかの驚きがあったときに見せる反応が楽しいのだとか。',
          '『過去のツケ』過去に、パートナーに秘密や弱味を握られた。それ以来、パートナーの手伝いをさせられている。まだ、逃げられていない。',
          '『必要な人材』パートナーに、自分が必要だと頼まれた。だから、一緒に事件を解決している。どうして自分が必要なのかは、まだわからない。',
          '『親しい人』パートナーにとって自分は、親しい人物だ。幼馴染や友人、親戚など。それ故に、昔から振り回されているし、これからも振り回されるだろう。',
          '『偶然の積み重ね』パートナーが事件に直面するたびに居合わせる。それが繰り返されるうちに、いつの間にか親しくなっていた。今では、一緒にいることも多い。',
        ]
        return get_table_by_1d6(table)
      end

      # 身長表
      def get_height_table
        table = [
          '非常に高い',
          '高め',
          '平均的',
          '低め',
          '非常に低い',
          'パートナーより少し高い／少し低い',
        ]

        return get_table_by_1d6(table)
      end

      # たまり場表
      def get_base_table
        table = [
          [1, 'PCが働いている職場'],
          [2, '静かな雰囲気の喫茶店'],
          [3, '騒がしい雰囲気の居酒屋'],
          [4, '探偵活動のために借りた事務所'],
          [5, 'PCのうち、どちらかの家'],
          [6, '行きつけの料理屋'],
          [7, '移動に使う車の中'],
          [8, '知り合いから譲り受けた倉庫'],
          [9, 'いつもパートナーと会う交差点'],
          [10, '二人だけが知っている秘密の場所'],
        ]
        diceText = @randomizer.roll_once(10)
        output = get_table_by_number(diceText, table)
        return output, diceText
      end

      # 関係表
      def get_guest_relation_table
        table = [
          [11, '昔のバディ'],
          [12, '友人'],
          [13, '親友'],
          [14, '顔見知り'],
          [15, '戦友'],
          [16, '腐れ縁'],
          [22, '過去に何かあった'],
          [23, 'いとこ'],
          [24, '友達の友達'],
          [25, '遠い親戚'],
          [26, '近所の人'],
          [33, '迷惑をかけた'],
          [34, '師匠'],
          [35, 'ネットで知り合った'],
          [36, '偶然知り合った'],
          [44, '前に一度だけ会った'],
          [45, 'パートナーのことで相談された'],
          [46, 'パートナーについて質問された'],
          [55, '幼馴染'],
          [56, 'パートナーを追っている'],
          [66, '一方的に知られている'],
        ]
        return get_table_by_d66_swap(table)
      end

      # 思い出の品決定表
      def get_memorial_item_table
        table = [
          [11, 'たまり場にずっと置いてある宅配ピザの箱'],
          [12, '一緒に解決した事件のファイル'],
          [13, '二人が出会うきっかけになった本'],
          [14, '二人で遊んだチェスボードや将棋盤'],
          [15, '二人の思い出が詰まったゲーム機'],
          [16, '自分たちを写した写真'],
          [22, '二人の捜査ノート'],
          [23, '一緒に使った掃除道具'],
          [24, '被害者から贈られたぬいぐるみ'],
          [25, '二人で一緒に座ったソファー'],
          [26, 'いつも座っている椅子'],
          [33, 'よく使う電話機'],
          [34, '二人の時を刻んだ時計'],
          [35, 'いつも置いてある机'],
          [36, '事件の解説をしたホワイトボードや黒板'],
          [44, 'なぜかある人体模型'],
          [45, 'お気に入りのコップ'],
          [46, '事件解決に使った小道具'],
          [55, '一緒に飲む約束をしたお酒やジュース'],
          [56, 'お気に入りの料理'],
          [66, '二人だけの秘密の交換日記'],
        ]
        return get_table_by_d66_swap(table)
      end

      # 職業表A
      def get_job_table_66
        table = [
          [11, 'パートナーと同じ'],
          [12, 'フリーター'],
          [13, '学生（優秀）'],
          [14, '学生（普通）'],
          [15, '学生（不真面目）'],
          [16, '教師・講師'],
          [22, 'パートナーと同じ'],
          [23, '会社員'],
          [24, '主夫・主婦'],
          [25, '自営業者'],
          [26, 'ディレッタント'],
          [33, 'パートナーと同じ'],
          [34, '刑事（新人）'],
          [35, '刑事（エリート）'],
          [36, '公務員'],
          [44, 'パートナーと同じ'],
          [45, '探偵助手'],
          [46, '探偵'],
          [55, 'パートナーと同じ'],
          [56, '無職'],
          [66, 'パートナーと同じ'],
        ]

        return get_table_by_d66_swap(table)
      end

      # 職業表B
      def get_job_table_10
        table = [
          [1, 'ディレッタント'],
          [2, '刑事'],
          [3, '探偵（有名）'],
          [4, '探偵（不人気）'],
          [5, '探偵助手'],
          [6, '研究者'],
          [7, '自営業者'],
          [8, '会社員'],
          [9, '作家'],
          [10, '学生'],
        ]

        diceText = @randomizer.roll_once(10)
        output = get_table_by_number(diceText, table)
        return output, diceText
      end

      # ファッション特徴表A
      def get_fashion_table_66
        table = [
          [11, '高級志向'],
          [12, 'スーツ'],
          [13, 'カジュアルウェア'],
          [14, 'フォーマルウェア'],
          [15, 'スポーツウェア'],
          [16, 'リーズナブル'],
          [22, 'サングラス'],
          [23, 'Yシャツ'],
          [24, 'Tシャツ'],
          [25, 'ネックレス'],
          [26, '帽子'],
          [33, 'ミリタリー風'],
          [34, 'ピアス'],
          [35, 'ジャージ'],
          [36, 'エクステ'],
          [44, '和服'],
          [45, '指輪'],
          [46, 'チョーカー'],
          [55, 'サンダル'],
          [56, 'ジャンパー'],
          [66, 'ファッションにこだわりがない'],
        ]
        return get_table_by_d66_swap(table)
      end

      # ファッション特徴表B
      def get_fashion_table_10
        table = [
          [1, 'スーツ'],
          [2, 'インバネスコート'],
          [3, '白衣'],
          [4, 'グローブ'],
          [5, 'パイプ'],
          [6, 'チョッキ'],
          [7, '和服'],
          [8, 'カラフルな色使い'],
          [9, 'パートナーと同じ'],
          [10, 'ファッションにこだわりがない'],
        ]

        diceText = @randomizer.roll_once(10)
        output = get_table_by_number(diceText, table)
        return output, diceText
      end

      # 好きなもの／嫌いなもの表A
      def get_like_dislike_table_66
        table = [
          [11, '死体'],
          [12, '犬'],
          [13, '猫'],
          [14, 'サスペンス'],
          [15, '物語'],
          [16, 'アイドル'],
          [22, '犯罪'],
          [23, 'オカルト'],
          [24, '健康'],
          [25, 'ジャンクフード'],
          [26, '高級な食事'],
          [33, 'ファッション'],
          [34, '権力'],
          [35, '名誉'],
          [36, '友情'],
          [44, 'おやつ'],
          [45, '地元'],
          [46, '家族'],
          [55, '警察'],
          [56, '音楽'],
          [66, '銃'],
        ]

        return get_table_by_d66_swap(table)
      end

      # 好きなもの／嫌いなもの表B
      def get_like_dislike_table_10
        table = [
          [1, '犯罪'],
          [2, '謎'],
          [3, '探偵'],
          [4, 'パートナー'],
          [5, 'パートナーの好きなもの'],
          [6, 'パートナーの嫌いなもの'],
          [7, '特になし'],
          [8, 'チェスや将棋などボードゲーム'],
          [9, '人間'],
          [10, '知らないこと'],
        ]

        diceText = @randomizer.roll_once(10)
        output = get_table_by_number(diceText, table)
        return output, diceText
      end

      # 感情表A
      def get_feeling_table_66
        table = [
          [11, '顔'],
          [12, '雰囲気'],
          [13, '外見'],
          [14, '捜査方法'],
          [15, '立ち振る舞い'],
          [16, '匂い'],
          [22, '存在そのもの'],
          [23, '言葉遣い'],
          [24, '趣味'],
          [25, 'なんとなく'],
          [26, '他人への態度'],
          [33, '金銭感覚'],
          [34, '生活習慣'],
          [35, '技能'],
          [36, '服装'],
          [44, '喋るタイミング'],
          [45, '倫理観'],
          [46, '自分への態度'],
          [55, '距離感'],
          [56, '自分との関係'],
          [66, '生活習慣'],
        ]

        return get_table_by_d66_swap(table)
      end

      # 感情表B
      def get_feeling_table_10
        table = [
          [1, '人間性'],
          [2, '趣味'],
          [3, '技能'],
          [4, 'なんとなく'],
          [5, '感覚'],
          [6, '雰囲気'],
          [7, '自分が知らないところ'],
          [8, '自分がよく知っているところ'],
          [9, '自分への態度'],
          [10, '自分との関係'],
        ]
        diceText = @randomizer.roll_once(10)
        output = get_table_by_number(diceText, table)
        return output, diceText
      end

      # 呼び名表A
      def get_name_to_call_table_66
        table = [
          [11, 'ダーリン、ハニー'],
          [12, '呼び捨て'],
          [13, '～くん'],
          [14, '～さん'],
          [15, '～ちゃん'],
          [16, '～様、～殿'],
          [22, '～先輩、～後輩'],
          [23, '相棒'],
          [24, 'あんた'],
          [25, 'あなた'],
          [26, '先生、センセ'],
          [33, '物で例える'],
          [34, '貴様、貴殿'],
          [35, 'てめえ、おまえ'],
          [36, 'あだ名'],
          [44, 'ユー'],
          [45, 'お前さん'],
          [46, '探偵くん、探偵さん'],
          [55, '親友'],
          [56, 'パートナーと同じ'],
          [66, '毎回呼び方が変わる'],
        ]

        return get_table_by_d66_swap(table)
      end

      # 呼び名表B
      def get_name_to_call_table_10
        table = [
          [1, '呼び捨て'],
          [2, '～くん'],
          [3, '～さん'],
          [4, '～ちゃん'],
          [5, '～様、～殿'],
          [6, '相棒'],
          [7, 'あんた、あなた'],
          [8, 'キミ'],
          [9, '愛しの～'],
          [10, 'あだ名'],
        ]

        diceText = @randomizer.roll_once(10)
        output = get_table_by_number(diceText, table)

        return output, diceText
      end
    end
  end
end
