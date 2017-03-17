package com.jieweifu.plugins.barcode.bean;

import android.os.Parcel;
import android.os.Parcelable;
import android.util.Log;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by panx on 2017/3/15.
 */
public class PageInfoBean implements Parcelable {
  private final static String TAG = "PageInfoBean";
  private String title;
  private String tipScan;
  private String tipInput;
  private String tipLoading;
  private String tipNetworkError;
  private String tipOffline;
  private String openButton;
  private String footerFirst;
  private String footerSecond;

  public PageInfoBean() {
  }

  protected PageInfoBean(Parcel in) {
    title = in.readString();
    tipScan = in.readString();
    tipInput = in.readString();
    tipLoading = in.readString();
    tipNetworkError = in.readString();
    tipOffline = in.readString();
    openButton = in.readString();
    footerFirst = in.readString();
    footerSecond = in.readString();
  }

  @Override
  public void writeToParcel(Parcel dest, int flags) {
    dest.writeString(title);
    dest.writeString(tipScan);
    dest.writeString(tipInput);
    dest.writeString(tipLoading);
    dest.writeString(tipNetworkError);
    dest.writeString(tipOffline);
    dest.writeString(openButton);
    dest.writeString(footerFirst);
    dest.writeString(footerSecond);
  }

  @Override
  public int describeContents() {
    return 0;
  }

  public static final Creator<PageInfoBean> CREATOR = new Creator<PageInfoBean>() {
    @Override
    public PageInfoBean createFromParcel(Parcel in) {
      return new PageInfoBean(in);
    }

    @Override
    public PageInfoBean[] newArray(int size) {
      return new PageInfoBean[size];
    }
  };

  public String getTitle() {
    return title;
  }

  public void setTitle(String title) {
    this.title = title;
  }

  public String getTipScan() {
    return tipScan;
  }

  public void setTipScan(String tipScan) {
    this.tipScan = tipScan;
  }

  public String getTipInput() {
    return tipInput;
  }

  public void setTipInput(String tipInput) {
    this.tipInput = tipInput;
  }

  public String getTipLoading() {
    return tipLoading;
  }

  public void setTipLoading(String tipLoading) {
    this.tipLoading = tipLoading;
  }

  public String getTipNetworkError() {
    return tipNetworkError;
  }

  public void setTipNetworkError(String tipNetworkError) {
    this.tipNetworkError = tipNetworkError;
  }

  public String getTipOffline() {
    return tipOffline;
  }

  public void setTipOffline(String tipOffline) {
    this.tipOffline = tipOffline;
  }

  public String getOpenButton() {
    return openButton;
  }

  public void setOpenButton(String openButton) {
    this.openButton = openButton;
  }

  public String getFooterFirst() {
    return footerFirst;
  }

  public void setFooterFirst(String footerFirst) {
    this.footerFirst = footerFirst;
  }

  public String getFooterSecond() {
    return footerSecond;
  }

  public void setFooterSecond(String footerSecond) {
    this.footerSecond = footerSecond;
  }
}
