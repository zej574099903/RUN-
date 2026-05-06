import Foundation

class AIService: ObservableObject {
    static let shared = AIService()
    private let apiKey = "sk-1365d79b76d641329fdba4a32400d7c9"
    private let endpoint = "https://api.deepseek.com/v1/chat/completions"
    
    @Published var coachingAdvice: String = "正在分析你的运动数据..."
    @Published var isAnalyzing: Bool = false
    
    func fetchCoachingAdvice(steps: [Double], lastWorkout: String) {
        self.isAnalyzing = true
        
        let stepsSummary = steps.isEmpty ? "暂无数据" : steps.map { "\(Int($0))" }.joined(separator: ", ")
        
        let prompt = """
        你是一名专业且有温度的AI跑步教练。请根据以下用户的最近运动数据给出分析建议：
        1. 最近一周步数序列：[\(stepsSummary)] 步/天
        2. 最近一次运动详情：\(lastWorkout)
        
        要求：
        - 语气要专业、鼓励、充满亲和力。
        - 总结要精炼（不超过80字）。
        - 必须给出一个具体的、可操作的小建议。
        """
        
        let parameters: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "system", "content": "你是一名专业的跑步教练。"],
                ["role": "user", "content": prompt]
            ],
            "stream": false
        ]
        
        guard let url = URL(string: endpoint) else { 
            self.updateAdvice("API 地址无效")
            return 
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60 // 延长到 60 秒
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            self.updateAdvice("请求打包失败")
            return
        }
        
        print("🚀 [AI Service] 开始请求 DeepSeek...")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isAnalyzing = false
                
                if let error = error {
                    print("❌ [AI Service] 网络错误: \(error.localizedDescription)")
                    self.coachingAdvice = "网络连接失败，请检查网络设置。"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.coachingAdvice = "服务器响应异常。"
                    return
                }
                
                print("📡 [AI Service] 响应状态码: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    if let data = data, let errorMsg = String(data: data, encoding: .utf8) {
                        print("❌ [AI Service] 错误详情: \(errorMsg)")
                    }
                    self.coachingAdvice = "AI 教练开小差了 (Error \(httpResponse.statusCode))"
                    return
                }
                
                if let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let choices = json["choices"] as? [[String: Any]],
                           let firstChoice = choices.first,
                           let message = firstChoice["message"] as? [String: Any],
                           let content = message["content"] as? String {
                            print("✅ [AI Service] 分析成功！")
                            self.coachingAdvice = content.trimmingCharacters(in: .whitespacesAndNewlines)
                        } else {
                            print("❌ [AI Service] JSON 解析格式不匹配")
                            self.coachingAdvice = "数据格式解析失败。"
                        }
                    } catch {
                        print("❌ [AI Service] JSON 解析异常: \(error.localizedDescription)")
                        self.coachingAdvice = "数据解析异常。"
                    }
                }
            }
        }.resume()
    }
    
    private func updateAdvice(_ msg: String) {
        DispatchQueue.main.async {
            self.isAnalyzing = false
            self.coachingAdvice = msg
        }
    }
}
