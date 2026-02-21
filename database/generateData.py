import datetime
from faker import Faker
fake = Faker()
import random
import json



def stable_image(user_id, index=0):
    return f"https://picsum.photos/seed/{user_id}-{index}/600/800"

fake.unique.clear()
def sql_str(value):
    if isinstance(value, str):
        return "'" + value.replace("'", "''") + "'"  # escape single quotes
    elif isinstance(value, list):
        return "'" + json.dumps(value) + "'"
    elif isinstance(value, bool):
        return 'TRUE' if value else 'FALSE'
    elif value is None:
        return 'NULL'
    else:
        return str(value)
def sql_array(arr):
    # Convert a Python list of strings into PostgreSQL array literal
    return "ARRAY[" + ",".join("'" + s.replace("'", "''") + "'" for s in arr) + "]"

queries =[]
for i in range(1000):
    gender = fake.random_element(elements=('Male', 'Female'))

    if gender == 'Male':
        name = fake.first_name_male()
    else:
        name = fake.first_name_female()
    email = fake.unique.email()
    password = fake.password() #reliable password hash
    birthday = fake.date_of_birth(minimum_age=18, maximum_age=60)
 

   

    profileUrl = stable_image(i)
    imagesUrl = [
        stable_image(i, 1),
        stable_image(i, 2),
        stable_image(i, 3),
    ]

    bio=fake.text(max_nb_chars=500)
    country =fake.country_code()
    onboarded = True
    created_at = fake.date_between_dates(date_start=datetime.date(2010, 1, 1), date_end=datetime.date(2023, 1, 1))
    last_login = created_at + datetime.timedelta(days=1)
    passwwordHash = "$2a$10$3DQdtDxDPWFWy9EF9Zo6J.1LM2KJ5VsPQj56QyWdAqggGfREjJIkK"

    userQuery = """
INSERT INTO users
(name, email, password_hash, gender, birthday, profile_url, images_url, bio, country, onboarded, created_at, last_login, email_verified)
VALUES
({name}, {email}, {passwordHash}, {gender}, {birthday}, {profileUrl}, {imagesUrl}, {bio}, {country}, {onboarded}, {created_at}, {last_login}, true);
"""

    queries.append(userQuery.format(
        name=sql_str(name),
        email=sql_str(email),
        passwordHash=sql_str(passwwordHash),  # fixed typo
        gender=sql_str(gender),
        birthday=sql_str(str(birthday)),
        profileUrl=sql_str(profileUrl),
        imagesUrl=sql_array(imagesUrl),
        bio=sql_str(bio),
        country=sql_str(country),
        onboarded=sql_str(onboarded),
        created_at=sql_str(str(created_at)),
        last_login=sql_str(str(last_login))
    ))

match_id=0
for i in range(20000):
    userId = fake.random_int(min=1, max=1000)
    userId2 = fake.random_int(min=1, max=1000)
    while userId2 == userId:
        userId2 = fake.random_int(min=1, max=1000)
    p1=0.3
    if p1 > random.random(): #match
        opinion = fake.text(max_nb_chars=500)
        opinion2 = fake.text(max_nb_chars=500)
        opinionQuery = "INSERT INTO opinions (sender_id, receiver_id, opinion) VALUES ({userId}, {userId2}, {opinion}) ON CONFLICT DO NOTHING ;"
        queries.append(opinionQuery.format(
            userId=userId,
            userId2=userId2,
            opinion=sql_str(opinion)
        ))

        queries.append(opinionQuery.format(userId=userId2, userId2=userId, opinion=sql_str(opinion2)))


        matchQuery = "INSERT INTO matches (id, user1_id, user2_id) VALUES ({id}, {userId}, {userId2}) ON CONFLICT DO NOTHING  ;\n"
        chatQuery = "INSERT INTO chats (id, user1_id, user2_id) VALUES ({id}, {userId}, {userId2}) ON CONFLICT DO NOTHING  ;\n"
        p=0.3

        match_id+=1
        if random.random() > p:
             queries.append(matchQuery.format(id=match_id, userId=userId, userId2=userId2))
        else:
            queries.append(matchQuery.format(id=match_id, userId=userId2, userId2=userId))
            queries.append("DELETE FROM matches WHERE id={id};\n".format(id=match_id))
            queries.append(chatQuery.format(id=match_id, userId=userId, userId2=userId2))
            
            # messageQuery = "INSERT INTO messages (chat_id, sender_id, receiver_id, content, is_read) VALUES ( {chat_id}, {userId}, {userId2}, {message}, {is_read}) ON CONFLICT DO NOTHING  ;\n"

            messageQuery ="""INSERT INTO messages (chat_id, sender_id, receiver_id, content, is_read)
SELECT id, {userId}, {userId2}, {message}, {is_read}
FROM chats 
WHERE id = {chat_id} -- This will only insert if the ID actually exists
LIMIT 1;"""

            message = fake.text(max_nb_chars=30)
            is_read = random.random() > 0.5
            if random.random() > 0.5:
                queries.append(messageQuery.format( chat_id=match_id, userId=userId, userId2=userId2, message=sql_str(message), is_read=sql_str(is_read)))

            else: 
                queries.append(messageQuery.format( chat_id=match_id, userId=userId2, userId2=userId, message=sql_str(message), is_read=sql_str(is_read)))


    else:
        #o enas opinion o allos skip

        p=0.9
        if random.random() < p:
            opinion = fake.text(max_nb_chars=500)
            opinionQuery = "INSERT INTO opinions (sender_id, receiver_id, opinion) VALUES ({userId}, {userId2}, {opinion}) ON CONFLICT DO NOTHING ;\n"
            queries.append(opinionQuery.format(userId=userId, userId2=userId2, opinion=sql_str(opinion)))
            
            skipQuery = "INSERT INTO skips (skipper, skipped) VALUES ({userId}, {userId2}) ON CONFLICT DO NOTHING ;\n"
            queries.append(skipQuery.format(userId=userId2, userId2=userId))
        else: #k oi dio skip
            skipQuery = "INSERT INTO skips (skipper, skipped) VALUES ({userId}, {userId2}) ON CONFLICT DO NOTHING ;\n"

            queries.append(skipQuery.format(userId=userId, userId2=userId2))
            queries.append(skipQuery.format(userId=userId2, userId2=userId))




f = open("populateDb.sql", "w", encoding="utf-8")
try:
    for query in queries:
          f.write(query)
finally:
    f.close()


    
