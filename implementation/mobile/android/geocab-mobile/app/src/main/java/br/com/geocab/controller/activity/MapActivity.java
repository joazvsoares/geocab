package br.com.geocab.controller.activity;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.AlertDialog;
import android.app.ProgressDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.res.Configuration;
import android.graphics.drawable.AnimationDrawable;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.support.v4.app.ActionBarDrawerToggle;
import android.support.v4.widget.DrawerLayout;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.view.inputmethod.InputMethodManager;
import android.webkit.JavascriptInterface;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebSettings.RenderPriority;
import android.webkit.WebView;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.facebook.Session;

import java.util.ArrayList;
import java.util.Locale;
import java.util.Map;

import br.com.geocab.R;
import br.com.geocab.controller.activity.dialog.DialogInformation;
import br.com.geocab.controller.adapter.NavDrawerListAdapter;
import br.com.geocab.controller.delegate.LayerDelegate;
import br.com.geocab.controller.delegate.MarkerDelegate;
import br.com.geocab.entity.GroupEntity;
import br.com.geocab.entity.Layer;
import br.com.geocab.entity.Marker;
import br.com.geocab.entity.User;
import br.com.geocab.util.JavaScriptHandler;

public class MapActivity extends Activity
{

    /*-------------------------------------------------------------------
	 *				 		     ATTRIBUTES
	 *-------------------------------------------------------------------*/

    /**
     * side menu
     */
    private DrawerLayout mDrawerLayout;
    /**
     * listview side menu
     */
    private ListView mDrawerList;
    /**
     * button to open side menu
     */
    private ActionBarDrawerToggle mDrawerToggle;
    /**
     * nav drawer adapter listview nav drawer
     */
    private NavDrawerListAdapter adapter;
    /**
     * web view map
     */
    private WebView webViewMap;
    /**
     * search layer edit text
     */
    private EditText searchLayerEditText;
    /**
     *
     */
    private Button buttonClearSearchLayerEditText;
    /**
     *
     */
    private Button buttonOpenMenu;

    /**
     *
     */
    private Button buttonLogout;
    /**
     * the layout side menu list
     */
    private LinearLayout linearLayoutLayer;
    /**
     *
     */
    private LayerDelegate layerDelegate;
    /**
     *
     */
    private TextView textViewSelectedCountItems;
    /**
     *
     */
    private TextView textViewTotalItems;

    /**
     *
     */
    private DialogInformation dialogInformation;

    private ProgressDialog progressDialog;

    /**
     *
     */
    boolean doubleBackToExitPressedOnce;

    /*-------------------------------------------------------------------
	 *				 		     HANDLERS
	 *-------------------------------------------------------------------*/

    /**
     * Called when the activity is starting
     *
     * @param savedInstanceState
     */
    @SuppressLint("JavascriptInterface")
    @Override
    protected void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);

        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
        WindowManager.LayoutParams.FLAG_FULLSCREEN);

        setContentView(R.layout.activity_map);

        textViewSelectedCountItems = (TextView) findViewById(R.id.text_view_count_selected_items);
        textViewTotalItems = (TextView) findViewById(R.id.text_view_total_items);

        webViewMap = (WebView) findViewById(R.id.web_view_map);
        webViewMap.getSettings().setJavaScriptEnabled(true);
        webViewMap.setLayerType(View.LAYER_TYPE_HARDWARE, null);
        webViewMap.getSettings().setRenderPriority(RenderPriority.HIGH);
        webViewMap.getSettings().setCacheMode(WebSettings.LOAD_NO_CACHE);
        webViewMap.setWebChromeClient(new WebChromeClient());
        webViewMap.loadUrl("file:///android_asset/map.html");

        //if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            webViewMap.setWebContentsDebuggingEnabled(true);
        //}

        webViewMap.addJavascriptInterface(this, "Android");

        searchLayerEditText = (EditText) findViewById(R.id.edit_text_search_layer);

        buttonClearSearchLayerEditText = (Button) findViewById(R.id.button_clear_edit_text);
        buttonClearSearchLayerEditText.setVisibility(RelativeLayout.INVISIBLE);
        buttonClearSearchLayerEditText.setOnClickListener(new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
            searchLayerEditText.setText("");
            }
        });

        searchLayerEditText.addTextChangedListener(new TextWatcher()
        {
            @Override
            public void onTextChanged(CharSequence cs, int arg1, int arg2, int arg3)
            {
                if( cs.length() > 0 )
                {
                    buttonClearSearchLayerEditText.setVisibility(RelativeLayout.VISIBLE);
                }
                else
                {
                    buttonClearSearchLayerEditText.setVisibility(RelativeLayout.INVISIBLE);
                }

            }

            @Override
            public void beforeTextChanged(CharSequence arg0, int arg1, int arg2, int arg3)
            {
            }

            @Override
            public void afterTextChanged(Editable arg0)
            {
                String text = searchLayerEditText.getText().toString().toLowerCase(Locale.getDefault());
                MapActivity.this.adapter.filter(text);
            }
        });

        linearLayoutLayer = (LinearLayout) findViewById(R.id.left_drawer);

        buttonOpenMenu = (Button) findViewById(R.id.btn_open_menu);
        buttonOpenMenu.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mDrawerLayout.openDrawer(linearLayoutLayer);
            }
        });

        buttonLogout = (Button) findViewById(R.id.btn_logout);
        buttonLogout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                openAlert(v);
            }
        });

        progressDialog = new ProgressDialog(this);
        dialogInformation = new DialogInformation(this);

        //NAV DRAWER

        mDrawerLayout=(DrawerLayout) findViewById(R.id.drawer_layout);

        mDrawerLayout.setDrawerLockMode(DrawerLayout.LOCK_MODE_LOCKED_CLOSED);

        mDrawerList=(ListView) findViewById(R.id.list_slidermenu);

        mDrawerList.setTextFilterEnabled(true);

        // setting the nav drawer list adapter
        Object[] objects = new Object[3];
        objects[0]= this.webViewMap;
        objects[1] = this.textViewSelectedCountItems;
        objects[2] = this.textViewTotalItems;

        adapter=new NavDrawerListAdapter(getApplicationContext(), 0,objects);
        mDrawerList.setAdapter(adapter);

        this.layerDelegate=new LayerDelegate(MapActivity.this, adapter);

        this.layerDelegate.listLayersPublished();

        mDrawerToggle=new ActionBarDrawerToggle(this,mDrawerLayout,
                        R.drawable.ic_drawer, //nav menu toggle icon
                        R.string.app_name, // nav drawer open - description for accessibility
                        R.string.app_name // nav drawer close - description for accessibility
                )
        {
        public void onDrawerClosed (View view)
        {
            hideSoftKeyboard(MapActivity.this);

            invalidateOptionsMenu();

            mDrawerLayout.setDrawerLockMode(DrawerLayout.LOCK_MODE_LOCKED_CLOSED);
        }

        public void onDrawerOpened(View drawerView)
        {
            hideSoftKeyboard(MapActivity.this);

            invalidateOptionsMenu();

            mDrawerLayout.setDrawerLockMode(DrawerLayout.LOCK_MODE_UNLOCKED);
        }

        };
        mDrawerLayout.setDrawerListener(mDrawerToggle);

    }

    /**
     * Dialog para sair ou permanecer na aplicação
     * @param view
     */
    private void openAlert(View view) {
        AlertDialog.Builder alertDialogBuilder = new AlertDialog.Builder(MapActivity.this);

        alertDialogBuilder.setTitle("Logout");
        alertDialogBuilder.setMessage("Tem certeza que deseja sair?");
        // set positive button: Yes message
        alertDialogBuilder.setPositiveButton("Sim",new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog,int id) {

                if (Session.getActiveSession() != null)
                {
                    Session.getActiveSession().closeAndClearTokenInformation();
                    Session.setActiveSession(null);
                }

                SplashScreenActivity.prefEditor = SplashScreenActivity.settings.edit();
                SplashScreenActivity.prefEditor.putString("email", null);
                SplashScreenActivity.prefEditor.putString("password", null);
                SplashScreenActivity.prefEditor.commit();

                startActivity(new Intent(MapActivity.this, AuthenticationActivity.class));
                finish();

            }
        });
        // set negative button: No message
        alertDialogBuilder.setNegativeButton("Não",new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog,int id) {
                // cancel the alert box and put a Toast to the user
                dialog.cancel();
            }
        });
        AlertDialog alertDialog = alertDialogBuilder.create();
        alertDialog.show();
    }

    @JavascriptInterface
    public void changeToAddMarker(String wktCoordenate){
        Intent intent = new Intent(MapActivity.this, MarkerActivity.class);
        intent.putExtra("wktCoordenate", wktCoordenate);
        startActivity(intent);
    }

    @JavascriptInterface
    public void showInformation( long markerId, String markerUser, String markerDate, String layerName, String[] listUrls, String[] listTitles)
    {
        if( markerId > 0 || listUrls != null )
        {
            Marker marker = new Marker(markerId, markerDate, new User("", markerUser) );
            marker.setLayer(new Layer(layerName, layerName));

            dialogInformation.showLoadMarkers(progressDialog);

            MarkerDelegate markerDelegate = new MarkerDelegate(this, dialogInformation);

            if( markerId > 0 && listUrls == null )
            {
                markerDelegate.downloadMarkerPicture(marker);
            }
            else if( markerId == 0 && listUrls != null )
            {
                for(int i = 0; i < listUrls.length; i++)
                {
                    markerDelegate.listLayerProperties(listUrls[i], listTitles[i]);
                }
            }
            else if(markerId > 0 && listUrls != null )
            {
                markerDelegate.downloadMarkerPicture(marker);

                for(int i = 0; i < listUrls.length; i++)
                {
                    markerDelegate.listLayerProperties(listUrls[i], listTitles[i]);
                }
            }
        }
    }

    /**
     *
     * Close keyboard
     *
     * @param activity
     */
    public static void hideSoftKeyboard(Activity activity)
    {
        InputMethodManager inputMethodManager = (InputMethodManager)  activity.getSystemService(Activity.INPUT_METHOD_SERVICE);
        inputMethodManager.hideSoftInputFromWindow(activity.getCurrentFocus().getWindowToken(), 0);
    }

    /**
     * When using the ActionBarDrawerToggle, you must call it during
     * onPostCreate() and onConfigurationChanged()...
     */

    /**
     *
     */
    @Override
    public void onBackPressed()
    {
        if (doubleBackToExitPressedOnce)
        {
            super.onBackPressed();
            MapActivity.this.finish();
            MapActivity.this.moveTaskToBack(true);
            return;
        }

        this.doubleBackToExitPressedOnce = true;

        Toast.makeText( this, R.string.click_exit, Toast.LENGTH_SHORT ).show();

        new Handler().postDelayed(new Runnable() {

            @Override
            public void run() {
                doubleBackToExitPressedOnce = false;
            }
        }, 2000);
    }

    /**
     *
     * @param savedInstanceState
     */
    @Override
    protected void onPostCreate(Bundle savedInstanceState) {
        super.onPostCreate(savedInstanceState);
        // Sync the toggle state after onRestoreInstanceState has occurred.
        mDrawerToggle.syncState();
    }

    /**
     *
     * @param newConfig
     */
    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        // Pass any configuration change to the drawer toggls
        mDrawerToggle.onConfigurationChanged(newConfig);
    }

}
