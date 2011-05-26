# class PostSweeper < ActionController::Caching::Sweeper
#   observe Post
  
#   # If we create a new post, index of articles must be regenerated
#   def after_create(post)
#     expire_index_page
#   end

# 	# If we update an existing post, the cached version of that post is stale
# 	def after_update(post)
# 		expire_post_page(post.id)
# 	end

# 	# Deleting a post means we update the index and blow away the cached post
# 	def after_destroy(post)
# 		expire_index_page
# 		expire_post_page(post.id)
# 	end
	
# 	private
# 		def expire_index_page
# 			expire_page(:controller => "post", :action => 'index')
# 		end

# 		def expire_post_page(post_id)
# 			expire_action(:controller => "post",
# 										:action => "show",
# 	                  :id => post_id)
# 	end
# end