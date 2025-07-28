package routes

import (
	"booonus-backend/api/handlers"
	"booonus-backend/api/middleware"

	"github.com/gin-gonic/gin"
)

// SetupRoutes 设置所有路由
func SetupRoutes() *gin.Engine {
	router := gin.Default()

	// 添加CORS中间件
	router.Use(middleware.CORS())

	// 公开路由（不需要认证）
	public := router.Group("/api/v1")
	{
		public.POST("/register", handlers.Register)
		public.POST("/login", handlers.Login)
	}

	// 需要认证的路由
	protected := router.Group("/api/v1")
	protected.Use(middleware.AuthMiddleware())
	{
		// 用户相关
		protected.GET("/profile", handlers.GetProfile)
		protected.PUT("/profile", handlers.UpdateProfile)

		// 情侣关系
		protected.POST("/couple/invite", handlers.InviteCouple)
		protected.POST("/couple/accept", handlers.AcceptCouple)
		protected.DELETE("/couple", handlers.RemoveCouple)
		protected.GET("/couple", handlers.GetCouple)

		// 积分相关
		protected.GET("/points", handlers.GetPoints)
		protected.GET("/points/history", handlers.GetPointsHistory)

		// 小卖部
		protected.GET("/shop", handlers.GetShopItems)
		protected.POST("/shop", handlers.CreateShopItem)
		protected.PUT("/shop/:id", handlers.UpdateShopItem)
		protected.DELETE("/shop/:id", handlers.DeleteShopItem)
		protected.POST("/shop/:id/buy", handlers.BuyShopItem)

		// 规则
		protected.GET("/rules", handlers.GetRules)
		protected.POST("/rules", handlers.CreateRule)
		protected.PUT("/rules/:id", handlers.UpdateRule)
		protected.DELETE("/rules/:id", handlers.DeleteRule)
		protected.POST("/rules/:id/execute", handlers.ExecuteRule)

		// 事件
		protected.GET("/events", handlers.GetEvents)
		protected.POST("/events", handlers.CreateEvent)

		// 撤销操作
		protected.POST("/revert/:id", handlers.RevertOperation)
	}

	return router
}
