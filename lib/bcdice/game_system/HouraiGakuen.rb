# frozen_string_literal: true

module BCDice
  module GameSystem
    class HouraiGakuen < Base
      # ゲームシステムの識別子
      ID = 'HouraiGakuen'

      # ゲームシステム名
      NAME = '蓬莱学園の冒険!!'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ほうらいかくえんのほうけん'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・基本ロール：ROL(x+n)
          ROLL(自分の能力値 + 簡単値 + 応石 or 蓬莱パワー)と記述します。3D6をロールし、成功したかどうかを表示します。
          例）ROL(4+6)
        ・対人判定：MED(x,y)
          自分の能力値 x と 相手の能力値 y でロールを行い、成功したかどうかを表示します。
          例）MED(5,2)
        ・対抗判定：RES(x,y)
          自分の能力値 x と 相手の能力値 y で相互にロールし、どちらが成功したかを表示します。両者とも成功 or 失敗の場合は引き分けとなります。
          例）RES(6,4)
        ・陰陽コマンド INY
          例）Hourai : 陽（奇数の方が多い）
        ・五行コマンド：GOG
          例）Hourai : 五行表(3) → 五行【土】
        ・八徳コマンド：HTK
          例）Hourai : 仁義八徳は、【義】(奇数、奇数、偶数)
      INFO_MESSAGE_TEXT

      register_prefix(['ROL.*', 'MED\(\d+,\d+\)', 'RES\(\d+,\d+\)', 'INY.*', 'HTK.*', 'GOG.*'])

      # ゲームの名前
      # チャット欄表示名
      # 判定用前置文字
      # 説明文
      # コマンド分岐
      def rollDiceCommand(command)
        case command
        when /^ROL/i
          return getRollResult(command)
        when /^MED/i
          return getMedResult(command)
        when /^RES/i
          return getResResult(command)
        when /^INY/i
          return getInnyouResult(command)
        when /^HTK/i
          return getHattokuResult(command)
        when /^GOG$/i
          return getGogyouResult(command)
        end

        return nil
      end

      CRITICAL = "大成功"
      SUCCESS = "成功"
      FAILURE = "失敗"
      FUMBLE = "大失敗"

      # 基本ロール
      def getRollResult(command)
        return nil unless /rol([-\d]+)/i =~ command

        # 目標値セット
        target = Regexp.last_match(1).to_i

        dice_list = @randomizer.roll_barabara(3, 6)
        total = dice_list.sum()
        diceText = dice_list.join(",")

        result = getCheckResult(dice_list, total, target)

        return "(3d6<=#{target}) ＞ 出目#{diceText}＝合計#{total} ＞ #{result}"
      end

      def getCheckResult(diceList, total, target)
        diceList = diceList.sort

        if isFamble(diceList)
          return FUMBLE
        end

        if isCritical(diceList)
          return CRITICAL
        end

        if total <= target
          return SUCCESS
        end

        return FAILURE
      end

      def isFamble(diceList)
        return diceList == [6, 6, 6]
      end

      def isCritical(diceList)
        return diceList == [1, 2, 3]
      end

      # 対人ロール
      def getMedResult(command)
        return nil unless /med\((\d+),(\d+)\)/i =~ command

        yourValue = Regexp.last_match(1).to_i # あなたの値
        enemyValue = Regexp.last_match(2).to_i # 相手の値
        target = getTargetFromValue(yourValue, enemyValue) # 値から目標値を作出

        dice_list = @randomizer.roll_barabara(3, 6)
        total = dice_list.sum()
        diceText = dice_list.join(",")

        result = getCheckResult(dice_list, total, target)

        return "(あなたの値#{yourValue}、相手の値#{enemyValue}、3d6<=#{target}) ＞ 出目#{diceText}＝合計#{total} ＞ #{result}"
      end

      def getTargetFromValue(yourValue, enemyValue)
        yourValue + (10 - enemyValue) # 値から目標値を作出
      end

      # 対抗ロール
      def getResResult(command)
        return nil unless /res\((\d+),(\d+)\)/i =~ command

        yourValue = Regexp.last_match(1).to_i # あなたの値
        enemyValue = Regexp.last_match(2).to_i # 相手の値

        # 値から目標値を作出
        yourTarget = getTargetFromValue(yourValue, enemyValue)
        enemyTarget = getTargetFromValue(enemyValue, yourValue)

        your_dice_list = @randomizer.roll_barabara(3, 6)
        yourTotal = your_dice_list.sum()
        yourDiceText = your_dice_list.join(",")

        enemy_dice_list = @randomizer.roll_barabara(3, 6)
        enemyTotal = enemy_dice_list.sum()
        enemyDiceText = enemy_dice_list.join(",")

        yourResult = getCheckResult(your_dice_list, yourTotal, yourTarget)
        enemyResult = getCheckResult(enemy_dice_list, enemyTotal, enemyTarget)

        result = getResistCheckResult(yourResult, enemyResult)

        return "あなたの値#{yourValue}、相手の値#{enemyValue}
(あなたのロール 3d6<=#{yourTarget}) ＞ #{yourDiceText}=#{yourTotal} ＞ #{yourResult}
(相手のロール 3d6<=#{enemyTarget}) ＞ #{enemyDiceText}=#{enemyTotal} ＞ #{enemyResult}
＞#{result}"
      end

      def getResistCheckResult(yourResult, enemyResult)
        yourRank = getResultRank(yourResult)
        enemyRank = getResultRank(enemyResult)

        if yourRank > enemyRank
          return "あなたが勝利"
        end

        if yourRank < enemyRank
          return "相手が勝利"
        end

        return "引き分け"
      end

      def getResultRank(result)
        ranks = [
          FUMBLE,
          FAILURE,
          SUCCESS,
          CRITICAL,
        ]

        return ranks.index(result)
      end

      # 陰陽コマンド
      def getInnyouResult(_command)
        oddCount = 0
        evenCount = 0

        3.times do
          dice = @randomizer.roll_once(6)

          if dice.even?
            evenCount += 1 # 偶数カウント
          else
            oddCount += 1 # 奇数カウント
          end
        end

        if evenCount < oddCount
          return "陽（奇数の方が多い）"
        else
          return "陰（偶数の方が多い）"
        end
      end

      # 八徳コマンド
      def getHattokuResult(_command)
        # 3回振って、奇数・偶数がどの順序で出たかを記録する
        oddEvenList = []
        3.times do
          oddEvenList << getOddEven
        end

        oddEvenText = oddEvenList.join("、")

        case oddEvenText
        when "奇数、奇数、奇数"
          return "仁義八徳は、【仁】(#{oddEvenText})"
        when "奇数、奇数、偶数"
          return "仁義八徳は、【義】(#{oddEvenText})"
        when "奇数、偶数、奇数"
          return "仁義八徳は、【礼】(#{oddEvenText})"
        when "奇数、偶数、偶数"
          return "仁義八徳は、【智】(#{oddEvenText})"
        when "偶数、奇数、奇数"
          return "仁義八徳は、【忠】(#{oddEvenText})"
        when "偶数、奇数、偶数"
          return "仁義八徳は、【信】(#{oddEvenText})"
        when "偶数、偶数、奇数"
          return "仁義八徳は、【孝】(#{oddEvenText})"
        when "偶数、偶数、偶数"
          return "仁義八徳は、【悌】(#{oddEvenText})"
        else
          return "異常終了"
        end
      end

      def getOddEven
        dice = @randomizer.roll_once(6)

        return "偶数" if dice.even?

        return "奇数"
      end

      def getGogyouResult(_command)
        type = '五行表'

        table = getGogyouTable
        text, number = get_table_by_1d6(table)

        output = "#{type}(#{number}) ＞ #{text}"
        return output
      end

      # 五行コマンド
      def getGogyouTable
        table = [
          '五行【木】',
          '五行【火】',
          '五行【土】',
          '五行【金】',
          '五行【水】',
          '五行は【任意選択】',
        ]
        return table
      end
    end
  end
end
