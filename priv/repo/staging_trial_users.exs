
# ---------------------------
## This script generates users and respective students for testing emails
## Args: [number_of_users]
# ---------------------------

import Ecto.Query

user_num = String.to_integer(Enum.at(System.argv, 0))

(1 .. user_num) |> Enum.each(fn number ->
    %{
        email: "carsonward12345+" <> to_string(number) <> "@gmail.com",
        password: "password",
        student: %{
            phone: Faker.Phone.EnUs.area_code() <> Faker.Phone.EnUs.exchange_code() <> Faker.Phone.EnUs.subscriber_number(),
            name_first: Faker.Name.En.first_name(),
            name_last: Faker.Name.En.last_name(),
            notification_time: "15:00:00.000",
            notification_days_notice: 1,
            future_reminder_notification_time: "15:00:00.000"}
        } 
        |> Skoller.Users.create_user([admin: true])
    end)

