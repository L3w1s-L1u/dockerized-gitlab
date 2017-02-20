# gitlab SMTP configurations
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.gmail.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "gitlabbuaauas@gmail.com"
gitlab_rails['smtp_password'] = "Bu@@u@s@g00gl3"
gitlab_rails['smtp_domain'] = "gmail.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'

# If your SMTP server does not like the default 'From: gitlab@localhost' you
# # can change the 'From' with this setting.
gitlab_rails['gitlab_email_from'] = 'gitlabbuaauas@gmail.com'
gitlab_rails['gitlab_email_reply_to'] = 'gitlabbuaauas@gmail.com'
