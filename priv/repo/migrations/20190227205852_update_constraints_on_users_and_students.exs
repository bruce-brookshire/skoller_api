defmodule Skoller.Repo.Migrations.UpdateConstraintsOnUsersAndStudents do
  use Ecto.Migration

  def up do
    #User references
    drop constraint("user_devices", "user_devices_user_id_fkey")
    drop constraint("user_reports", "user_reports_user_id_fkey")
    drop constraint("email_logs", "email_logs_user_id_fkey")
    drop constraint("email_jobs", "email_jobs_user_id_fkey")

    #Student references
    drop constraint("student_points", "student_points_student_id_fkey")
    drop constraint("student_fields_of_study", "student_fields_of_study_student_id_fkey")
    drop constraint("chat_posts", "chat_posts_student_id_fkey")
    drop constraint("chat_comments", "chat_comments_student_id_fkey")
    drop constraint("chat_replies", "chat_replies_student_id_fkey")
    drop constraint("chat_post_likes", "chat_post_likes_student_id_fkey")
    drop constraint("chat_comment_likes", "chat_comment_likes_student_id_fkey")
    drop constraint("chat_reply_likes", "chat_reply_likes_student_id_fkey")
    drop constraint("chat_post_stars", "chat_post_stars_student_id_fkey")
    drop constraint("chat_comment_stars", "chat_comment_stars_student_id_fkey")
    drop constraint("assignment_posts", "assignment_posts_student_id_fkey")
    drop constraint("custom_signups", "custom_signups_student_id_fkey")

    #User references
    alter table(:user_devices) do
      modify :user_id, references(:users, on_delete: :delete_all)
    end
    alter table(:user_reports) do
      modify :user_id, references(:users, on_delete: :delete_all)
    end
    alter table(:email_logs) do
      modify :user_id, references(:users, on_delete: :delete_all)
    end
    alter table(:email_jobs) do
      modify :user_id, references(:users, on_delete: :delete_all)
    end

    #Student references
    alter table(:student_points) do
      modify :student_id, references(:students, on_delete: :delete_all)
    end
    alter table(:student_fields_of_study) do
      modify :student_id, references(:students, on_delete: :delete_all)
    end
    alter table(:chat_posts) do
      modify :student_id, references(:students, on_delete: :delete_all)
    end
    alter table(:chat_comments) do
      modify :student_id, references(:students, on_delete: :delete_all)
    end
    alter table(:chat_replies) do
      modify :student_id, references(:students, on_delete: :delete_all)
    end
    alter table(:chat_post_likes) do
      modify :student_id, references(:students, on_delete: :delete_all)
    end
    alter table(:chat_comment_likes) do
      modify :student_id, references(:students, on_delete: :delete_all)
    end
    alter table(:chat_reply_likes) do
      modify :student_id, references(:students, on_delete: :delete_all)
    end
    alter table(:chat_post_stars) do
      modify :student_id, references(:students, on_delete: :delete_all)
    end
    alter table(:chat_comment_stars) do
      modify :student_id, references(:students, on_delete: :delete_all)
    end
    alter table(:assignment_posts) do
      modify :student_id, references(:students, on_delete: :delete_all)
    end
    alter table(:custom_signups) do
      modify :student_id, references(:students, on_delete: :delete_all)
    end
  end

  def down do
    #User references
    drop constraint("user_devices", "user_devices_user_id_fkey")
    drop constraint("user_reports", "user_reports_user_id_fkey")
    drop constraint("email_logs", "email_logs_user_id_fkey")
    drop constraint("email_jobs", "email_jobs_user_id_fkey")

    #Student references
    drop constraint("student_points", "student_points_student_id_fkey")
    drop constraint("student_fields_of_study", "student_fields_of_study_student_id_fkey")
    drop constraint("chat_posts", "chat_posts_student_id_fkey")
    drop constraint("chat_comments", "chat_comments_student_id_fkey")
    drop constraint("chat_replies", "chat_replies_student_id_fkey")
    drop constraint("chat_post_likes", "chat_post_likes_student_id_fkey")
    drop constraint("chat_comment_likes", "chat_comment_likes_student_id_fkey")
    drop constraint("chat_reply_likes", "chat_reply_likes_student_id_fkey")
    drop constraint("chat_post_stars", "chat_post_stars_student_id_fkey")
    drop constraint("chat_comment_stars", "chat_comment_stars_student_id_fkey")
    drop constraint("assignment_posts", "assignment_posts_student_id_fkey")
    drop constraint("custom_signups", "custom_signups_student_id_fkey")

    #User references
    alter table(:user_devices) do
      modify :user_id, references(:users, on_delete: :nothing)
    end
    alter table(:user_reports) do
      modify :user_id, references(:users, on_delete: :nothing)
    end
    alter table(:email_logs) do
      modify :user_id, references(:users, on_delete: :nothing)
    end
    alter table(:email_jobs) do
      modify :user_id, references(:users, on_delete: :nothing)
    end

    #Student references
    alter table(:student_points) do
      modify :student_id, references(:students, on_delete: :nothing)
    end
    alter table(:student_fields_of_study) do
      modify :student_id, references(:students, on_delete: :nothing)
    end
    alter table(:chat_posts) do
      modify :student_id, references(:students, on_delete: :nothing)
    end
    alter table(:chat_comments) do
      modify :student_id, references(:students, on_delete: :nothing)
    end
    alter table(:chat_replies) do
      modify :student_id, references(:students, on_delete: :nothing)
    end
    alter table(:chat_post_likes) do
      modify :student_id, references(:students, on_delete: :nothing)
    end
    alter table(:chat_comment_likes) do
      modify :student_id, references(:students, on_delete: :nothing)
    end
    alter table(:chat_reply_likes) do
      modify :student_id, references(:students, on_delete: :nothing)
    end
    alter table(:chat_post_stars) do
      modify :student_id, references(:students, on_delete: :nothing)
    end
    alter table(:chat_comment_stars) do
      modify :student_id, references(:students, on_delete: :nothing)
    end
    alter table(:assignment_posts) do
      modify :student_id, references(:students, on_delete: :nothing)
    end
    alter table(:custom_signups) do
      modify :student_id, references(:students, on_delete: :nothing)
    end
  end
end
