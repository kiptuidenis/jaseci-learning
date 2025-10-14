import streamlit as st;
import requests;

def bootstrap_frontend(token: str) {
    st.set_page_config(layout="wide");
    st.title("StudyGPT");

    if "messages" not in st.session_state {
        st.session_state.messages = [];
    }
    if "session_id" not in st.session_state {
        st.session_state.session_id = "user_session_123";
    }

    # Display chat messages
    for message in st.session_state.messages {
        with st.chat_message(message["role"]) {
            st.markdown(message["content"]);
        }
    }

    if prompt := st.chat_input("Ask me anything...") {
        st.session_state.messages.append({"role": "user", "content": prompt});

        with st.chat_message("user") {
            st.markdown(prompt);
        }

        with st.chat_message("assistant") {
            with st.spinner("Thinking...") {
                payload = {
                    "message": prompt,
                    "session_id": st.session_state.session_id
                };

                response = requests.post(
                    "http://localhost:8000/walker/interact",
                    json=payload,
                    headers={"Authorization": f"Bearer {token}"}
                );

                if response.status_code == 200 {
                    data = response.json();
                    reply = data["reports"][0]["response"];

                    if type(reply) == dict {
    ::py::
    for key, value in reply.items():
        with st.container():
            st.markdown(f"### {key}")
            st.markdown(value)
            
            # Add a collapsible sub-chat option
            with st.expander("💬 Ask more about this concept"):
                sub_question = st.text_input(f"Follow-up on '{key}'", key=f"follow_{key}")
                if st.button(f"Ask about {key}", key=f"btn_{key}"):
                    sub_payload = {
                        "message": sub_question or f"Tell me more about {key}",
                        "session_id": st.session_state.session_id
                    }
                    sub_response = requests.post(
                        "http://localhost:8000/walker/interact",
                        json=sub_payload,
                        headers={"Authorization": f"Bearer {token}"}
                    )
                    if sub_response.status_code == 200:
                        sub_data = sub_response.json()
                        sub_reply = sub_data["reports"][0]["response"]
                        st.markdown("#### Sub Chat Response:")
                        if type(sub_reply) == dict:
                            for sub_key, sub_value in sub_reply.items():
                                st.markdown(f"**{sub_key}**")
                                st.markdown(sub_value)
                        else:
                            st.markdown(sub_reply)
                    else:
                        st.error(f"Error: {sub_response.text}")

            # store original message
            st.session_state.messages.append({"role": "assistant", "content": f"{key}: {value}"})
    ::py::
} else {
    st.markdown(reply);
    st.session_state.messages.append({"role": "assistant", "content": reply});
}



                } else {
                    st.error(f"Error: {response.text}");
                }
            }
        }
    }
}

with entry {
    INSTANCE_URL = "http://localhost:8000";
    TEST_USER_EMAIL = "test@mail.com";
    TEST_USER_PASSWORD = "password";

    response = requests.post(
        f"{INSTANCE_URL}/user/login",
        json={"email": TEST_USER_EMAIL, "password": TEST_USER_PASSWORD}
    );

    if response.status_code != 200 {
        response = requests.post(
            f"{INSTANCE_URL}/user/register",
            json={"email": TEST_USER_EMAIL, "password": TEST_USER_PASSWORD}
        );
        assert response.status_code == 201;

        response = requests.post(
            f"{INSTANCE_URL}/user/login",
            json={"email": TEST_USER_EMAIL, "password": TEST_USER_PASSWORD}
        );
    }

    token = response.json()["token"];
    print("Token:", token);
    bootstrap_frontend(token);
}
