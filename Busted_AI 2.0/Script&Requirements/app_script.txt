import streamlit as st
import pandas as pd
import numpy as np
import tensorflow as tf
from sklearn.preprocessing import StandardScaler
import plotly.express as px
import io
from fpdf import FPDF

# ============================================================
# PAGE CONFIG
# ============================================================
st.set_page_config(page_title="💳 BUSTED AI 2.0", layout="wide")

st.markdown(
    """
    <style>
    .main {
        background-color: #0f1116;
        color: white;
    }
    .stButton>button {
        background-color: #06d6a0;
        color: black;
        border-radius: 10px;
        font-weight: 600;
    }
    .stFileUploader label {
        color: #06d6a0;
    }
    .metric-card {
        background-color: #1c1e26;
        padding: 15px;
        border-radius: 12px;
        text-align: center;
        box-shadow: 0 0 10px rgba(0,0,0,0.4);
    }
    </style>
    """,
    unsafe_allow_html=True,
)

st.title("💳 BUSTED AI 2.0 — Fraud Detection & Customer Segmentation")
st.caption("Developed by Faizan | BUSTED AI 2.0 © 2025")

# ============================================================
# LOAD MODELS
# ============================================================
@st.cache_resource
def load_models():
    fraud_model = tf.keras.models.load_model("fraud_detection_model.keras", compile=False)
    seg_model = tf.keras.models.load_model("customer_segmentation_model.keras", compile=False)
    return fraud_model, seg_model

fraud_model, seg_model = load_models()
scaler = StandardScaler()

# ============================================================
# HELPER FUNCTIONS
# ============================================================

def process_csv(uploaded_file):
    data = pd.read_csv(uploaded_file)
    non_num_cols = data.select_dtypes(include=["object"]).columns
    if len(non_num_cols) > 0:
        st.warning(f"Dropped non-numeric columns: {list(non_num_cols)}")
        data = data.drop(columns=non_num_cols)
    data = data.fillna(data.median(numeric_only=True))
    return data

def match_input_shape(data, model):
    expected_dim = model.input_shape[1]
    current_dim = data.shape[1]
    if current_dim > expected_dim:
        data = data.iloc[:, :expected_dim]
    elif current_dim < expected_dim:
        pad = np.zeros((data.shape[0], expected_dim - current_dim))
        data = np.concatenate([data.values, pad], axis=1)
        data = pd.DataFrame(data)
    return data

def predict_fraud(data):
    data = match_input_shape(data, fraud_model)
    data_scaled = scaler.fit_transform(data)
    preds = fraud_model.predict(data_scaled)
    return preds.flatten()

def predict_segment(data):
    data = match_input_shape(data, seg_model)
    data_scaled = scaler.fit_transform(data)
    preds = seg_model.predict(data_scaled)
    return preds

def generate_pdf(df, filename="output.pdf"):
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", size=10)
    pdf.cell(200, 10, txt="BUSTED AI 2.0 Prediction Report", ln=True, align="C")
    pdf.ln(10)
    for i, col in enumerate(df.columns):
        pdf.cell(200, 8, txt=f"{col}: {df[col].iloc[0]}", ln=True)
    buf = io.BytesIO()
    pdf.output(buf)
    buf.seek(0)
    return buf

# ============================================================
# FEATURE NAMES
# ============================================================
fraud_features = [
    "amount", "oldbalanceOrg", "newbalanceOrig", "oldbalanceDest", "newbalanceDest",
    "balanceChangeOrig", "balanceChangeDest", "AmountTOBalanceRatio", "BalanceErrorOrig",
    "MerchantDest", "isTransfer", "isCashOut", "isPayment", "type_DEBIT", "type_TRANSFER", "encoded_transactionSize"
]

seg_features = [
    "BALANCE", "BALANCE_FREQUENCY", "PURCHASES", "ONEOFF_PURCHASES",
    "INSTALLMENTS_PURCHASES", "CASH_ADVANCE", "PURCHASES_FREQUENCY",
    "ONEOFF_PURCHASES_FREQUENCY", "CASH_ADVANCE_FREQUENCY", "CASH_ADVANCE_TRX",
    "PURCHASES_TRX", "CREDIT_LIMIT", "PAYMENTS", "MINIMUM_PAYMENTS",
    "PRC_FULL_PAYMENT", "TOTAL_SPENDING"
]

# ============================================================
# TABS
# ============================================================
tab1, tab2 = st.tabs(["🚨 Fraud Detection", "👥 Customer Segmentation"])

# -------------------------- FRAUD DETECTION --------------------------
with tab1:
    st.subheader("🧠 Fraud Detection System")

    method = st.radio("Choose Input Method:", ("📤 Upload CSV", "🧮 Manual Input"), horizontal=True)

    if method == "📤 Upload CSV":
        file = st.file_uploader("Upload your Fraud Detection CSV file", type=["csv"])
        if file:
            try:
                df = process_csv(file)
                preds = predict_fraud(df)
                df["Fraud Probability"] = preds
                df["Predicted Label"] = (preds > 0.5).astype(int)

                st.dataframe(df.head(10))

                fig = px.histogram(df, x="Fraud Probability", nbins=20, title="Fraud Probability Distribution")
                st.plotly_chart(fig, use_container_width=True)

                fraud_rate = (df["Predicted Label"].mean()) * 100
                st.metric("Fraudulent Transactions (%)", f"{fraud_rate:.2f}%")

                # Download Buttons
                st.download_button("⬇️ Download CSV", df.to_csv(index=False), "fraud_predictions.csv", "text/csv")
            except Exception as e:
                st.error(f"❌ Error: {e}")

    else:
        st.write("### Enter Transaction Details:")
        inputs = {}
        cols = st.columns(4)
        for i, feat in enumerate(fraud_features):
            with cols[i % 4]:
                inputs[feat] = st.number_input(f"{feat}", value=0.0, step=0.01)

        if st.button("🔎 Predict Fraud"):
            df_manual = pd.DataFrame([inputs])
            preds = predict_fraud(df_manual)
            prob = preds[0]
            label = "⚠️ Fraudulent" if prob > 0.5 else "✅ Legitimate"
            st.success(f"Prediction: {label} | Probability: {prob:.3f}")

            fig = px.bar(x=["Legitimate", "Fraudulent"], y=[1 - prob, prob], color=["green", "red"],
                         title="Fraud Probability Visualization")
            st.plotly_chart(fig, use_container_width=True)

            pdf_data = generate_pdf(pd.DataFrame([inputs]))
            st.download_button("⬇️ Download PDF Report", pdf_data, "fraud_result.pdf", "application/pdf")

# ---------------------- CUSTOMER SEGMENTATION -----------------------
with tab2:
    st.subheader("👥 Customer Segmentation System")

    seg_method = st.radio("Choose Input Method:", ("📤 Upload CSV", "🧮 Manual Input"), horizontal=True, key="seg_radio")

    if seg_method == "📤 Upload CSV":
        seg_file = st.file_uploader("Upload your Customer Data CSV", type=["csv"])
        if seg_file:
            try:
                seg_df = process_csv(seg_file)
                preds = predict_segment(seg_df)
                preds_df = pd.DataFrame(preds, columns=[f"Segment_{i+1}" for i in range(preds.shape[1])])
                st.dataframe(preds_df.head(10))

                fig = px.imshow(preds_df.corr(), text_auto=True, title="Customer Segmentation Feature Correlation")
                st.plotly_chart(fig, use_container_width=True)

                st.download_button("⬇️ Download Segmentation CSV", preds_df.to_csv(index=False),
                                   "segmentation_results.csv", "text/csv")
            except Exception as e:
                st.error(f"❌ Error: {e}")

    else:
        st.write("### Enter Customer Details:")
        seg_inputs = {}
        cols = st.columns(4)
        for i, feat in enumerate(seg_features):
            with cols[i % 4]:
                seg_inputs[feat] = st.number_input(f"{feat}", value=0.0, step=0.01, key=f"seg_{feat}")

        if st.button("🧩 Predict Segment"):
            df_seg_manual = pd.DataFrame([seg_inputs])
            preds = predict_segment(df_seg_manual)
            st.success(f"Customer Segment Prediction Vector: {np.round(preds[0], 3)}")

            fig = px.bar(x=[f"Segment_{i+1}" for i in range(len(preds[0]))],
                         y=preds[0],
                         title="Customer Segment Strengths",
                         color=[f"Segment_{i+1}" for i in range(len(preds[0]))])
            st.plotly_chart(fig, use_container_width=True)

            pdf_data = generate_pdf(pd.DataFrame([seg_inputs]))
            st.download_button("⬇️ Download PDF Report", pdf_data, "segment_result.pdf", "application/pdf")
